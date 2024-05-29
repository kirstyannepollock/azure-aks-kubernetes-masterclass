source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh

if [[ $1 = "init" ]]; then

    kubectl apply -f ../../azure-aks-kubernetes-masterclass/03-Kubernetes-Fundamentals-with-kubectl/03-02-ReplicaSets-with-kubectl/replicaset-demo.yml

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
