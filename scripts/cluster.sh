source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh
COMMANDS="stop start state"
COMMAND=$1

if [[ -z $COMMAND ]]; then
    echo "must supply command [ $COMMANDS ] !"
    exit 1
fi

case $COMMAND in
"stop")
    az aks stop --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP
    ;;
"start")
    az aks start --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP
    ;;
"state")
    az aks show --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP | jq -r  '. |  {name: .name, nodeResourceGroup: .nodeResourceGroup, powerState: .powerState.code}'
    ;;
*)
    echo "Invalid command. Use one of [ $COMMANDS ]"
    ;;
esac
