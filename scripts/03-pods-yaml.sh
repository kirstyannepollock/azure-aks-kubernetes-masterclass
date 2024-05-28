source $(dirname "$0")/set-credentials.sh

echo pod...
kubectl get pod my-first-pod -o yaml

echo service...
kubectl get service my-first-service -o yaml  