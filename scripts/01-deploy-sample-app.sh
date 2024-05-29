source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh

# Deploy Application
kubectl apply -f ../../azure-aks-kubernetes-masterclass/01-Create-AKS-Cluster/kube-manifests/

# # Verify Pods
kubectl get pods

# # Verify Deployment
kubectl get deployment

echo contacting service...
sleep 10

URL=$(getK8sServiceUrl myapp1-loadbalancer)
curl $URL 

