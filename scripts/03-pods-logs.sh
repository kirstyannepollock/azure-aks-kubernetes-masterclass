source $(dirname "$0")/set-credentials.sh

kubectl get pods
kubectl logs my-first-pod

# stream
# kubectl logs -f my-first-pod


