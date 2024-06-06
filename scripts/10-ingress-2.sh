COMMANDS="create-public-ip install-ingress-controller apply-manifests show contact delete"
COMMAND=$1

if [[ -z $COMMAND ]]; then
    echo "must supply command [ $COMMANDS ] !"
    exit 1
fi

source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh
function getPublicIpAddress() {
    az network public-ip list | jq -r --arg NAME "$IP_NAME" '.[] | select(.name == $NAME) | .ipAddress'
}

MC_RG=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query nodeResourceGroup -o tsv)

case $COMMAND in
"create-public-ip")
    IP_ADDRESS=$(az network public-ip create --resource-group $MC_RG --name $IP_NAME --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv)

    echo
    echo IP ADDRESS
    echo =============
    echo $IP_ADDRESS
    ;;
"install-ingress-controller")
    if [[ -z $2 ]]; then
        REPLICA_COUNT=2
    else
        REPLICA_COUNT=$2
    fi

    # Create a namespace for your ingress resources
    echo creating namespace $INGRESS_NAMESPACE ...
    kubectl create namespace $INGRESS_NAMESPACE

    echo
    echo adding Helm repo for ingress-nginx...
    # Add the official stable repository
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update

    STATIC_IP=$(getPublicIpAddress)

    echo
    echo installing $REPLICA_COUNT replicas of ingress-nginx on $STATIC_IP ns=$INGRESS_NAMESPACE...

    # # Azure AKS won't work without "controller.service.externalTrafficPolicy=Local"
    helm install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace $INGRESS_NAMESPACE \
        --set controller.replicaCount=$REPLICA_COUNT \
        --set controller.nodeSelector."kubernetes\.io/os"=linux \
        --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
        --set controller.service.externalTrafficPolicy=Local \
        --set controller.service.loadBalancerIP="$STATIC_IP"

    # alt but would need full YAML to tweak those abpove values I assume
    # kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml

    echo =================================================
    echo "*** If this operation failed, check taints! ***"
    echo =================================================

    kubectl get service -l app.kubernetes.io/name=ingress-nginx --namespace $INGRESS_NAMESPACE
    ;;
"apply-manifests")
    if [[ -z $2 ]]; then
        DIR_NAME=../10-Ingress-Context-Path-Based-Routing/kube-manifests
    else
        DIR_NAME=$2
    fi
    kubectl apply -R -f $DIR_NAME/
    ;;
"delete")
    if [[ -z $2 ]]; then
        DIR_NAME=../10-Ingress-Context-Path-Based-Routing/kube-manifests
    else
        DIR_NAME=$2
    fi
    kubectl delete -R -f $DIR_NAME/
    helm uninstall ingress-nginx ingress-nginx/ingress-nginx \
        --namespace $INGRESS_NAMESPACE
    helm repo remove ingress-nginx https://kubernetes.github.io/ingress-nginx

    az network public-ip delete --resource-group $MC_RG --name $IP_NAME
    az network public-ip show --resource-group $MC_RG --name $IP_NAME
    kubectl delete namespace $INGRESS_NAMESPACE
    ;;
"show")
    kubectl get all -n $INGRESS_NAMESPACE

    if [[ "pod-logs" == $2 ]]; then

        PODS=$(kubectl get pods -n $INGRESS_NAMESPACE -o json | jq '.items | flatten | map({name: .metadata.name})')

        jq -r '.[]|[.name] | @tsv' <<<$PODS | while IFS=$'\t' read -r name; do
            echo
            echo ==============================================
            echo POD: $name
            echo ==============================================

            kubectl logs $name -n $INGRESS_NAMESPACE
        done

    fi
    ;;
"contact")
    HEALTH_CHECK_ENDPOINT=$2
    SERVICE_NAME=ingress-nginx-controller
    URL=$(getK8sServiceUrl $SERVICE_NAME $INGRESS_NAMESPACE)

    for APP in app1 app2; do
        echo
        echo ==============================================
        echo contacting app $APP ...
        echo ==============================================

        curl $URL/$APP/index.html
    done

    echo
    echo ====================================================
    echo Now go to $URL and login
    echo ====================================================
    echo Username: admin101
    echo Password: password101
    ;;

\?)
    echo "Use one of [ $COMMANDS ] " >&2
    ;;
*)
    echo "Invalid command $COMMAND. Use one of [ $COMMANDS ] " >&2
    exit 1
    ;;
esac
