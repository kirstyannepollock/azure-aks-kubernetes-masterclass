COMMANDS="create delete show install-controller contact apply-manifests"
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
"create")
    IP_ADDRESS=$(az network public-ip create --resource-group $MC_RG --name $IP_NAME --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv)

    echo
    echo IP ADDRESS
    echo =============
    echo $IP_ADDRESS
    ;;
"delete")
    # kubectl delete pods --all
    # kubectl delete services --all --namespace $INGRESS_NAMESPACE
    # kubectl delete ingress --all

    if [[ -z $2 ]]; then
        DIR_NAME=../09-Ingress-Basic/kube-manifests
    else
        DIR_NAME=$2
    fi
    kubectl delete -f $DIR_NAME/

    helm uninstall ingress-nginx ingress-nginx/ingress-nginx \
        --namespace $INGRESS_NAMESPACE
    helm repo remove ingress-nginx https://kubernetes.github.io/ingress-nginx
    kubectl delete namespace -n $INGRESS_NAMESPACE

    az network public-ip delete --resource-group $MC_RG --name $IP_NAME
    az network public-ip show --resource-group $MC_RG --name $IP_NAME

    ;;
"show")
    IP_ADDRESS=$(getIPAddress)
    echo STATIC IP ADDRESS
    echo =================
    echo $IP_ADDRESS
    echo
    echo STATIC IP ADDRESS DETAILS
    echo =========================
    az network public-ip show --resource-group $MC_RG --name $IP_NAME

    echo
    echo NAMESPACE DETAILS
    echo =================
    kubectl get all -n $INGRESS_NAMESPACE

    echo
    echo ALL
    echo ====
    kubectl get all
    ;;
"install-controller")
    REPLICA_COUNT=2
    # Create a namespace for your ingress resources
    kubectl create namespace $INGRESS_NAMESPACE

    # Add the official stable repository
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    he HEALTH_CHECK_ENDPOINT=$2
    lm repo update

    STATIC_IP=$(getIPAddress)
    helm install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace $INGRESS_NAMESPACE \
        --set controller.replicaCount=$REPLICA_COUNT \
        --set controller.nodeSelector."kubernetes\.io/os"=linux \
        --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
        --set controller.service.externalTrafficPolicy=Local \
        --set controller.service.loadBalancerIP="$STATIC_IP"
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
"apply-manifests")
    if [[ -z $2 ]]; then
        DIR_NAME=../09-Ingress-Basic/kube-manifests
    else
        DIR_NAME=$2
    fi
    kubectl apply -f $DIR_NAME/
    kubectl get services
    kubectl get ingress
    ;;
\?)
    echo "Use one of [ $COMMANDS ] " >&2
    ;;
*)
    echo "Invalid command $COMMAND. Use one of [ $COMMANDS ] " >&2
    exit 1
    ;;
esac
