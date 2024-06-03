COMMANDS="create-static-ip, delete, show"

if [[ -z $1 ]]; then
    echo "must supply command [ $COMMANDS ] !"
    exit 1
fi

COMMAND=$1
echo $COMMAND

source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh

function jsonArrayToTable() {
    jq -r '(.[0] | ([keys[] | .] |(., map(length*"-")))), (.[] | ([keys[] as $k | .[$k]])) | @tsv' | column -t -s $'\t'
}

case $COMMAND in
"create-static-ip")
    RG=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query nodeResourceGroup -o tsv)
    IP_ADDRESS=$(az network public-ip create --resource-group $RG --name myAKSPublicIPForIngress --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv)
    
    az network public-ip list | jq .[] | map()
    echo
    echo IP ADDRESS
    echo ==========
    echo $IP_ADDRESS
    ;;
"delete") ;;
"show") ;;
\?)
    echo "Invalid command. Use one of [ $COMMANDS ] " >&2
    exit 1
    ;;
esac
