COMMANDS="create, delete, show"

if [[ -z $1 ]]; then
    echo "must supply command [ $COMMANDS ] !"
    exit 1
fi

if [[ -z $2 ]]; then
    IP_NAME=myAKSPublicIPForIngress
else
    IP_NAME=$2
fi

COMMAND=$1

source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh

function jsonArrayToTable() {
    jq -r '(.[0] | ([keys[] | .] |(., map(length*"-")))), (.[] | ([keys[] as $k | .[$k]])) | @tsv' | column -t -s $'\t'
}

MC_RG=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query nodeResourceGroup -o tsv)

case $COMMAND in
"create")
    IP_ADDRESS=$(az network public-ip create --resource-group $MC_RG --name $IP_NAME --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv)

    echo
    echo IP ADDRESS
    echo =============
    echo $IP_ADDRESS
    ;;
"delete")
    az network public-ip delete --resource-group $MC_RG --name $IP_NAME
    az network public-ip show --resource-group $MC_RG --name $IP_NAME
    ;;
"show")
    IP_ADDRESS=$(az network public-ip list | jq -r --arg NAME "$IP_NAME" '.[] | select(.name == $NAME) | .ipAddress')
    echo IP ADDRESS
    echo =============
    echo $IP_ADDRESS
    echo
    echo DETAILS
    echo =============
    az network public-ip show --resource-group $MC_RG --name $IP_NAME

    ;;
\?)
    echo "Invalid command. Use one of [ $COMMANDS ] " >&2
    exit 1
    ;;
esac
