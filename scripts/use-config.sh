if [[ -z $1 ]]; then
    echo must supply JSON config!
    exit 1
fi

if [[ -z $2 ]]; then
    echo "must supply command [apply, destroy, show, check] !"
    exit 1
fi

COMMAND=$2
CONFIG_FILE=$1

source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh

CONFIGS=$(jq -r '' $CONFIG_FILE)

# Get the length of the list:
LENGTH=$(echo $CONFIGS | jq length)

function getParameters() {
    i=$1
    CONFIG=$(jq -r ".[$i]" <<<$CONFIGS)

    TYPE=$(jq -r .type <<<$CONFIG)
    DEPLOYMENT_NAME=$(jq -r .deploymentName <<<$CONFIG)
    IMAGE_NAME=$(jq -r .imageName <<<$CONFIG)
    IMAGE_VERSION=$(jq -r .imageVersion <<<$CONFIG)
    PORT=$(jq -r .port <<<$CONFIG)
    TARGET_PORT=$(jq -r .targetPort <<<$CONFIG)
    SERVICE_NAME=$(jq -r .serviceName <<<$CONFIG)
}

case $COMMAND in
"apply")
    for ((i = 0; i < $LENGTH; ++i)); do
        getParameters $i
        echo creating "$TYPE $DEPLOYMENT_NAME as $SERVICE_NAME using $IMAGE_NAME:$IMAGE_VERSION on $PORT:$TARGET_PORT..."
        echo IMAGE: "$IMAGE_NAME:$IMAGE_VERSION"
        kubectl create deployment $DEPLOYMENT_NAME --image="$IMAGE_NAME:$IMAGE_VERSION"
        kubectl expose deployment $DEPLOYMENT_NAME --type=$TYPE --port=$PORT --target-port=$TARGET_PORT --name=$SERVICE_NAME

        if [[ $TYPE = "loadBalancer" ]]; then
            echo front end URL: "$(getK8sServiceUrl $SERVICE_NAME)"
        fi
    done

    kubectl get services
    kubectl get pods -o wide
    ;;
"destroy")
    for ((i = 0; i < $LENGTH; ++i)); do
        getParameters $i

        echo destroying $DEPLOYMENT_NAME as $SERVICE_NAME
        kubectl delete deployment $DEPLOYMENT_NAME
        kubectl delete service $SERVICE_NAME
    done
    ;;
"show")
    kubectl get pods -o wide

    for ((i = 0; i < $LENGTH; ++i)); do
        getParameters $i

        kubectl get service $SERVICE_NAME
        kubectl get deployment $DEPLOYMENT_NAME
        echo "IMAGE"
        kubectl -ojson get deployment $DEPLOYMENT_NAME | jq -r .spec.template.spec.containers[0].image

        TYPE=$(jq -r .type <<<$CONFIG)
        HEALTH_CHECK_ENDPOINT=$(jq -r .healthCheckEndpoint <<<$CONFIG)

        if [[ $TYPE = "LoadBalancer" ]]; then
            URL=$(getK8sServiceUrl $SERVICE_NAME)
            HC="$URL/$HEALTH_CHECK_ENDPOINT"
            echo contacting $SERVICE_NAME on $HC ...
            curl $HC
            echo
        fi
    done
    ;;
"check")
    for ((i = 0; i < $LENGTH; ++i)); do
        getParameters $i

        echo will create "$TYPE $DEPLOYMENT_NAME as $SERVICE_NAME using $IMAGE_NAME:$IMAGE_VERSION on $PORT:$TARGET_PORT..."

    done

    kubectl get services
    kubectl get pods -o wide
    ;;
\?)
    echo "Invalid command. Use one of [apply, destroy, show, check] " >&2
    exit 1
    ;;
esac
