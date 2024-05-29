source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh

DEPLOYMENT_FILE="../../azure-aks-kubernetes-masterclass/03-Kubernetes-Fundamentals-with-kubectl/03-02-ReplicaSets-with-kubectl/replicaset-demo.yml"

if [[ $1 = "init" ]]; then

    kubectl apply -f $DEPLOYMENT_FILE
    kubectl describe rs my-helloworld-rs

    echo pods...
    # Get list of Pods with Pod IP and Node in which it is running
    kubectl get pods -o wide

    # Expose ReplicaSet as a Service
    kubectl expose rs my-helloworld-rs --type=LoadBalancer --port=80 --target-port=8080 --name=my-helloworld-rs-service

    echo contact service ...
    sleep 20
fi

URL="$(getK8sServiceUrl my-helloworld-rs-service)/hello"
curl $URL
echo

if [[ $1 = "replace" ]]; then
    kubectl replace -f $DEPLOYMENT_FILE
    kubectl get pods -o wide
fi

if [[ $1 = "delete" ]]; then
    kubectl delete -f $DEPLOYMENT_FILE
    kubectl delete service my-helloworld-rs-service
fi