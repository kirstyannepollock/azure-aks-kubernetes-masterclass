source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh

## todo - get these from maybe a JSON config with port, target port, version.
IMAGE_NAME_BACKEND=ghcr.io/stacksimplify/kube-helloworld:1.0.0
DEPLOYMENT_NAME_BACKEND=my-backend-rest-app
SERVICE_NAME_BACKEND=my-backend-service

IMAGE_NAME_FRONTEND=ghcr.io/stacksimplify/kube-frontend-nginx:1.0.0
DEPLOYMENT_NAME_FRONTEND=my-frontend-nginx-app
SERVICE_NAME_FRONTEND=my-frontend-service

if [[ $1 = "apply" ]]; then
    if [[ -z $2 ]]; then
        echo must supply config!
        exit 1
    fi

    CONFIGS=$(jq -r '' $2)

    # Get the length of the list:
    LENGTH=$(echo $CONFIGS | jq length)

    # Iterate through to store the names:
    for ((i = 0; i < $LENGTH; ++i)); do
        CONFIG=$(jq -r ".[$i]" <<<$CONFIGS)

        TYPE=$(jq -r .type <<<$CONFIG)
        DEPLOYMENT_NAME=$(jq -r .deploymentName <<<$CONFIG)
        IMAGE_NAME=$(jq -r .imageName <<<$CONFIG)
        IMAGE_VERSION=$(jq -r .imageVersion <<<$CONFIG)
        PORT=$(jq -r .port <<<$CONFIG)
        TARGET_PORT=$(jq -r .targetPort <<<$CONFIG)
        SERVICE_NAME=$(jq -r .serviceName <<<$CONFIG)

        echo creating "$TYPE $DEPLOYMENT_NAME as $SERVICE_NAME using $IMAGE_NAME:$IMAGE_VERSION $PORT:$TARGET_PORT..."

        kubectl create deployment $DEPLOYMENT_NAME --image=$IMAGE_NAME:$IMAGE_VERSION
        kubectl expose deployment $DEPLOYMENT_NAME --type=$TYPE --port=$PORT --target-port=$TARGET_PORT --name=$SERVICE_NAME

        if [[ $TYPE = "loadBalancer" ]]; then
            echo front end URL: "$(getK8sServiceUrl $SERVICE_NAME)"
        fi
    done

    kubectl get services
    kubectl get pods -o wide
fi

if [[ $1 = "destroy" ]]; then
    if [[ -z $2 ]]; then
        echo must supply config!
        exit 1
    fi

    CONFIGS=$(jq -r '' $2)

    # Get the length of the list:
    LENGTH=$(echo $CONFIGS | jq length)

    # Iterate through to store the names:
    for ((i = 0; i < $LENGTH; ++i)); do
        CONFIG=$(jq -r ".[$i]" <<<$CONFIGS)
        DEPLOYMENT_NAME=$(jq -r .deploymentName <<<$CONFIG)
        SERVICE_NAME=$(jq -r .serviceName <<<$CONFIG)

        echo destroying $DEPLOYMENT_NAME as $SERVICE_NAME
        kubectl delete deployment $DEPLOYMENT_NAME
        kubectl delete service $SERVICE_NAME
    done
fi

if [[ $1 = "show-all" ]]; then
    if [[ -z $2 ]]; then
        echo must supply config!
        exit 1
    fi

    CONFIGS=$(jq -r '' $2)

    # Get the length of the list:
    LENGTH=$(echo $CONFIGS | jq length)

    # Iterate through to store the names:
    for ((i = 0; i < $LENGTH; ++i)); do
        CONFIG=$(jq -r ".[$i]" <<<$CONFIGS)
        DEPLOYMENT_NAME=$(jq -r .deploymentName <<<$CONFIG)
        SERVICE_NAME=$(jq -r .serviceName <<<$CONFIG)

        kubectl get service $SERVICE_NAME
        kubectl get deployment $DEPLOYMENT_NAME
        echo "IMAGE"
        kubectl -ojson get deployment $DEPLOYMENT_NAME | jq -r .spec.template.spec.containers[0].image
        kubectl get pods -o wide
    done
fi

if [[ $1 = "init" ]]; then

    echo creating backend ...
    kubectl create deployment $DEPLOYMENT_NAME_BACKEND --image=$IMAGE_NAME_BACKEND
    kubectl expose deployment $DEPLOYMENT_NAME_BACKEND --type=ClusterIP --port=8080 --target-port=8080 --name=$SERVICE_NAME_BACKEND

    echo creating frontend ...
    kubectl create deployment $DEPLOYMENT_NAME_FRONTEND --image=$IMAGE_NAME_FRONTEND
    kubectl expose deployment $DEPLOYMENT_NAME_FRONTEND --type=LoadBalancer --port=80 --target-port=80 --name=$SERVICE_NAME_FRONTEND

    kubectl get services
    kubectl get pods -o wide
fi

if [[ $1 = "show" ]]; then
    case $2 in
    "fe")
        DEPLOYMENT_NAME=$DEPLOYMENT_NAME_FRONTEND
        SERVICE_NAME=$SERVICE_NAME_FRONTEND
        echo front end URL: "$(getK8sServiceUrl $SERVICE_NAME_FRONTEND)"
        ;;
    "be")
        DEPLOYMENT_NAME=$DEPLOYMENT_NAME_BACKEND
        SERVICE_NAME=$SERVICE_NAME_BACKEND
        ;;
    \?)
        echo "Invalid option -$2" >&2
        exit 1
        ;;
    esac

    kubectl get service $SERVICE_NAME
    kubectl get deployment $DEPLOYMENT_NAME
    echo "IMAGE"
    kubectl -ojson get deployment $DEPLOYMENT_NAME | jq -r .spec.template.spec.containers[0].image
    #kubectl describe deployment $DEPLOYMENT_NAME
    kubectl get pods -o wide

fi

if [[ $1 = "contact" ]]; then
    URL="$(getK8sServiceUrl $SERVICE_NAME_FRONTEND)/hello"
    echo contacting $SERVICE_NAME_FRONTEND on $URL ...
    curl $URL
    echo
fi

if [[ $1 = "scale" ]]; then
    kubectl scale --replicas=$2 deployment/$DEPLOYMENT_NAME_BACKEND
    kubectl get pods -o wide
fi

if [[ $1 = "delete" ]]; then
    kubectl delete deployment $DEPLOYMENT_NAME_BACKEND
    kubectl delete service $SERVICE_NAME_BACKEND
    kubectl delete deployment $DEPLOYMENT_NAME_FRONTEND
    kubectl delete service $SERVICE_NAME_FRONTEND
fi
