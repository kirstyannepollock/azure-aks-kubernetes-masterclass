function getK8sServiceUrl() {
    local SERVICE_NAME="$1"
    local NAMESPACE=$2
    INFO=$(kubectl -ojson get service $SERVICE_NAME -n $NAMESPACE)
    IP_ADDRESS=$(jq -r .status.loadBalancer.ingress[0].ip <<<$INFO)
    PORT=$(jq -r .spec.ports[0].port <<<$INFO)
    echo "http://$IP_ADDRESS:$PORT"
}
