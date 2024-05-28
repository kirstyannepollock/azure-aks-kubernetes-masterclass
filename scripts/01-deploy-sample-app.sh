source $(dirname "$0")/set-credentials.sh

# Deploy Application
kubectl apply -f ../../azure-aks-kubernetes-masterclass/01-Create-AKS-Cluster/kube-manifests/

# # Verify Pods
kubectl get pods

# # Verify Deployment
kubectl get deployment

# Verify Service (Make a note of external ip)
kubectl get service

# DATA=$(kubectl get service -o json)
# echo $DATA
# # !!!!! too much faff for now

# Access Application
#curl http://4.182.108.161

#http://<External-IP-from-get-service-output>
