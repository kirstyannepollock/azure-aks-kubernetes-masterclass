source $(dirname "$0")/set-credentials.sh

kubectl delete svc my-first-service
kubectl delete pod my-first-pod
