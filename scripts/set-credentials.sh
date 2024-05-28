source $(dirname "$0")/set-variables.sh
az account set --subscription $SUBSCRIPTION_NAME

az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME

# Replace Resource Group & Cluster Name
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME