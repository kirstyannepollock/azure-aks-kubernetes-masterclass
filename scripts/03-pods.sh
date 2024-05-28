source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh

echo starting pod...
kubectl run my-first-pod --image ghcr.io/stacksimplify/kubenginx:1.0.0

echo exposing service...
kubectl expose pod my-first-pod --type=LoadBalancer --port=80 --name=my-first-service

echo contacting service...
sleep 10

URL=$(getK8sServiceUrl my-first-service)
curl $URL 

