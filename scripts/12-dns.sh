COMMANDS="build-json delete"
COMMAND=$1

if [[ -z $COMMAND ]]; then
    echo "must supply command [ $COMMANDS ] !"
    exit 1
fi

source $(dirname "$0")/set-credentials.sh
source $(dirname "$0")/get-k8s-service-url.sh

TENANT_ID=$(az account show | jq -r .tenantId)
SUBSCRIPTION_ID=$(az account show | jq -r .id)
RG_DNS_ZONES=dns-zones
DNS_ZONE_NAME=kubeoncloud.com
MSI_NAME=aksdemo1-externaldns-access-to-dnszones

function getUAII() {
    az identity show --name $MSI_NAME --resource-group $RESOURCE_GROUP | jq -r .clientId
}

function buildAzureJson() {
    UAII=$1
    RG=$2
    echo $(jo tenantId=$TENANT_ID \
        subscriptionId=$SUBSCRIPTION_ID \
        resourceGroup=$RG \
        useManagedIdentityExtension=true \
        userAssignedIdentityID=$UAII)
}
case $COMMAND in
"assign-to-aks")
    # az aks update --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --enable-managed-identity
    # az aks nodepool upgrade --resource-group $RESOURCE_GROUP --cluster-name $AKS_CLUSTER_NAME --name agentpool --node-image-only
   az aks update \
    --resource-group myResourceGroup \
    --name myManagedCluster \
    --enable-managed-identity \
    --assign-identity <identity-resource-id> 5
   
    ;;
"build-json")
    buildAzureJson $(getUAII) $RESOURCE_GROUP
    ;;
"create-dns-zone")
    az group create --location germanywestcentral --name $RG_DNS_ZONES
    az network dns zone create -g $RG_DNS_ZONES -n $DNS_ZONE_NAME
    ;;
"add-msi")
    echo creating MSI $MSI_NAME in resource group $RESOURCE_GROUP
    UAII=$(az identity create --name $MSI_NAME --resource-group $RESOURCE_GROUP | jq -r .clientId)
    SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_DNS_ZONES"
    echo creating role assigment for $UAII with scope $SCOPE

    # MS say to use assignee-principal-type ServicePrincipal for MSI
    ROLE_ASSIGNMENT=$(
        az role assignment create \
            --assignee-object-id $UAII \
            --assignee-principal-type ServicePrincipal \
            --role Contributor \
            --scope $SCOPE
    )
    echo $ROLE_ASSIGNMENT
    ;;
"delete")
    az identity delete --name $MSI_NAME --resource-group $RESOURCE_GROUP
    az network dns zone delete -g $RG_DNS_ZONES -n $DNS_ZONE_NAME
    az group delete --name $RG_DNS_ZONES --yes --no-wait
    ;;
\?)
    echo "Use one of [ $COMMANDS ] " >&2
    ;;
*)
    echo "Invalid command $COMMAND. Use one of [ $COMMANDS ] " >&2
    exit 1
    ;;
esac
