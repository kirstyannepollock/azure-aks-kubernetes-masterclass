if [[ -z $1 ]]; then
    echo must supply YAML config!
    exit 1
fi

if [[ -z $2 ]]; then
    echo "must supply command [apply, delete, show, check] !"
    exit 1
fi

COMMAND=$2
YAML_FILE=$1
FRONTEND_SERVICE_NAME=$3
HEALTH_CHECK_ENDPOINT=$4

FRONTEND_DEPLOYMENT_NAME=frontend-nginxapp

source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh

function jsonArrayToTable() {
    jq -r '(.[0] | ([keys[] | .] |(., map(length*"-")))), (.[] | ([keys[] as $k | .[$k]])) | @tsv' | column -t -s $'\t'
}

case $COMMAND in
"apply")
    kubectl apply -f $YAML_FILE
    kubectl get services
    kubectl get pods -o wide
    ;;
"delete")
    kubectl delete -f $YAML_FILE
    kubectl get services
    kubectl get pods
    ;;
"show")
    echo DEPLOYMENTS
    echo ===========
    kubectl get deployments

    echo
    echo SERVICES
    echo ========
    kubectl get services

    echo
    echo PODS
    echo ====
    kubectl get pods -o wide

    echo
    DATA=$(kubectl -ojson get deployments | jq -r '.items | flatten | map(.spec.template.spec.containers) | flatten | map({image,name}) ')
    echo $DATA | jsonArrayToTable
    ;;
"contact")

    if [[ "$FRONTEND_SERVICE_NAME" = "" ]]; then
        echo must supply FRONTEND_SERVICE_NAME as param 3 !
        exit 1
    fi

    # echo getting URL for $FRONTEND_SERVICE_NAME
    URL=$(getK8sServiceUrl $FRONTEND_SERVICE_NAME)
    # echo $URL
    HC="$URL/$HEALTH_CHECK_ENDPOINT"
    echo contacting $FRONTEND_SERVICE_NAME on $HC ...
    curl $HC
    echo
    ;;
"check")
    kubeconform -summary -output json $YAML_FILE
    ;;
\?)
    echo "Invalid command. Use one of [apply, delete, show, check] " >&2
    exit 1
    ;;
esac
