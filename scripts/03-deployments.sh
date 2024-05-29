source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh

#DEPLOYMENT_FILE="../../azure-aks-kubernetes-masterclass/03-Kubernetes-Fundamentals-with-kubectl/03-02-ReplicaSets-with-kubectl/replicaset-demo.yml"

DEPLOYMENT_NAME=my-first-deployment
SERVICE_NAME=$DEPLOYMENT_NAME-service

if [[ $1 = "init" ]]; then
    kubectl create deployment $DEPLOYMENT_NAME --image=ghcr.io/stacksimplify/kubenginx:1.0.0
    kubectl expose deployment $DEPLOYMENT_NAME --type=LoadBalancer --port=80 --target-port=80 --name=$SERVICE_NAME
    kubectl get services
    kubectl get pods -o wide
fi

if [[ $1 = "update" ]]; then
    kubectl set image deployment/$DEPLOYMENT_NAME kubenginx=stacksimplify/kubenginx:2.0.0
    INFO=$(kubectl -ojson get deployment $DEPLOYMENT_NAME)
    IMAGE=$(jq -r .spec.template.spec.containers[0].image <<<$INFO)
    echo "IMAGE"
    echo $IMAGE

fi

if [[ $1 = "show" ]]; then
    kubectl get services
    kubectl get deployments
    echo "IMAGE"
    kubectl -ojson get deployment $DEPLOYMENT_NAME | jq -r .spec.template.spec.containers[0].image
    kubectl get replicaset
    kubectl get pods -o wide
fi

if [[ $1 = "contact" ]]; then
    URL="$(getK8sServiceUrl $SERVICE_NAME)"
    echo contacting $SERVICE_NAME on $URL ...
    curl $URL
    echo
fi

if [[ $1 = "scale" ]]; then
    kubectl scale --replicas=$2 deployment/$DEPLOYMENT_NAME
    kubectl get pods -o wide
fi

if [[ $1 = "delete" ]]; then
    kubectl delete deployment $DEPLOYMENT_NAME
    kubectl delete service $SERVICE_NAME
fi
