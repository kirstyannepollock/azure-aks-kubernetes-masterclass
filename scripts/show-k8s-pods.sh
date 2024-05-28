source $(dirname "$0")/set-credentials.sh

# List Pods from all namespaces
kubectl get pods --all-namespaces

# useful for fault-finding
# kubectl describe pod nginx-pod