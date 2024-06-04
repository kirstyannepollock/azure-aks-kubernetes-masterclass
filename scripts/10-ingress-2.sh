COMMANDS="create-public-ip apply-manifests create-controller show contact delete"
COMMAND=$1

if [[ -z $COMMAND ]]; then
    echo "must supply command [ $COMMANDS ] !"
    exit 1
fi

source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh
function getIPAddress() {
    az network public-ip list | jq -r --arg NAME "$IP_NAME" '.[] | select(.name == $NAME) | .ipAddress'
}

MC_RG=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query nodeResourceGroup -o tsv)
IP_NAME=myAKSPublicIPForIngress
INGRESS_NAMESPACE=ingress-basic

case $COMMAND in
"create-public-ip")
    IP_ADDRESS=$(az network public-ip create --resource-group $MC_RG --name $IP_NAME --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv)

    echo
    echo IP ADDRESS
    echo =============
    echo $IP_ADDRESS
    ;;
"install-controller")
    REPLICA_COUNT=2
    # Create a namespace for your ingress resources
    kubectl create namespace $INGRESS_NAMESPACE

    # Add the official stable repository
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update

    STATIC_IP=$(getIPAddress)
    helm install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace $INGRESS_NAMESPACE \
        --set controller.replicaCount=$REPLICA_COUNT \
        --set controller.nodeSelector."kubernetes\.io/os"=linux \
        --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
        --set controller.service.externalTrafficPolicy=Local \
        --set controller.service.loadBalancerIP="$STATIC_IP"
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
    kubectl get pods
    kubectl get services
    kubectl get ingress
    kubectl get pods -n $INGRESS_NAMESPACE
    PODS=$(kubectl get pods -n ingress-basic -o json | jq '.items | flatten | map({name: .metadata.name})')

    jq -r '.[]|[.name] | @tsv' <<<$PODS | while IFS=$'\t' read -r name; do
        echo POD: $name
        kubectl logs $name -n $INGRESS_NAMESPACE
    done
    ;;
"contact")
    HEALTH_CHECK_ENDPOINT=$2
    SERVICE_NAME=ingress-nginx-controller
    URL=$(getK8sServiceUrl $SERVICE_NAME $INGRESS_NAMESPACE)
    echo $URL
    HC="$URL/$HEALTH_CHECK_ENDPOINT" ##  /app1/index.html
    echo contacting $SERVICE_NAME on $HC ...
    curl $HC
    echo
    ;;

\?)
    echo "Use one of [ $COMMANDS ] " >&2
    ;;
*)
    echo "Invalid command $COMMAND. Use one of [ $COMMANDS ] " >&2
    exit 1
    ;;
esac
