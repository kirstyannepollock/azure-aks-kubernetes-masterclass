source $(dirname "$0")/set-credentials.sh

# List all k8s objects from Cluster Control plane
kubectl get all --all-namespaces