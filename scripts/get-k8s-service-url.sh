function getK8sServiceUrl() {

    local SERVICE_NAME="$1"
    INFO=$(kubectl -ojson get service $SERVICE_NAME)
    IP_ADDRESS=$(jq -r .status.loadBalancer.ingress[0].ip <<<$INFO)
    PORT=$(jq -r .spec.ports[0].port <<<$INFO)
    echo "http://$IP_ADDRESS:$PORT"
}
