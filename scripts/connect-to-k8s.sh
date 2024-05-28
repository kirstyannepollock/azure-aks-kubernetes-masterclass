source $(dirname "$0")/set-credentials.sh

# List Kubernetes Worker Nodes
kubectl get nodes 
kubectl get nodes -o wide