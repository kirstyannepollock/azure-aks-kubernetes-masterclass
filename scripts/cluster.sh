source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh
COMMANDS="stop start state scale-all"
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
    az aks show --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP | jq -r '. |  {name: .name, nodeResourceGroup: .nodeResourceGroup, powerState: .powerState.code}'
    ;;
"show")
    kubectl get all --all-namespaces
    ;;
"scale-all")
    REPLICA_COUNT=$2
    if [[ -z $REPLICA_COUNT ]]; then
        echo "must supply number of replicas as parameter 2 !"
        exit 1
    fi

    NAMESPACES=$3
    if [[ -z $NAMESPACES ]]; then
        NAMESPACES="default $INGRESS_NAMESPACE"
    fi

    echo "scaling to $REPLICA_COUNT all pods in namespace(s) $NAMESPACES"
    kubectl scale statefulset,deployment --namespace "$NAMESPACES" --replicas=0 --all
    kubectl get pods --namespace "$NAMESPACES"
    ;;
*)
    echo "Invalid command. Use one of [ $COMMANDS ]"
    ;;

esac
