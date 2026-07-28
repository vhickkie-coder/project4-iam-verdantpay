#!/bin/bash
set -e

# ==== Configuration ====
RESOURCE_GROUP="rg-verdantpay-iam"
LOCATION="southafricanorth"
VNET_NAME="vnet-verdantpay"
SUBSCRIPTION_ID="f6a1c9ee-95ed-4bbb-9f16-e72d2dad5499"
WEBADMINS_GROUP="WebAdmins"
DBADMINS_GROUP="DBAdmins"

echo "Starting Verdant Pay IAM deployment..."

 # ==== Resource Group + Network ====
echo "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

echo "Creating VNet with Web subnet..."
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefix 10.20.0.0/16 \
  --subnet-name snet-web \
  --subnet-prefix 10.20.1.0/24

echo "Creating DB subnet..."
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name snet-db \
  --address-prefix 10.20.2.0/24

# ==== Azure AD Groups ====
echo "Creating WebAdmins group..."
az ad group create --display-name $WEBADMINS_GROUP --mail-nickname $WEBADMINS_GROUP

echo "Creating DBAdmins group..."
az ad group create --display-name $DBADMINS_GROUP --mail-nickname $DBADMINS_GROUP

# ==== Test User Provisioning ====
DOMAIN=$(az rest --method get --url "https://graph.microsoft.com/v1.0/domains" --query "value[0].id" -o tsv)

echo "Creating intern test user..."
az ad user create --display-name "InternTestUser" --user-principal-name "internuser@$DOMAIN" --password TempPass123.ChangeMe --force-change-password-next-sign-in true

INTERN_ID=$(az ad user show --id "internuser@$DOMAIN" --query id -o tsv)
az ad group member add --group $WEBADMINS_GROUP --member-id $INTERN_ID
echo "Intern user added to $WEBADMINS_GROUP."

# ==== Role Assignments ====
WEBADMINS_ID=$(az ad group show --group $WEBADMINS_GROUP --query id -o tsv)
DBADMINS_ID=$(az ad group show --group $DBADMINS_GROUP --query id -o tsv)

echo "Assigning Contributor to WebAdmins on Web subnet..."
az role assignment create \
  --assignee $WEBADMINS_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-web"

echo "Assigning Reader to DBAdmins on VNet..."
az role assignment create \
  --assignee $DBADMINS_ID \
  --role "Reader" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME"

echo "Deployment complete."

# ==== Offboarding Function ====
offboard_user() {
  USER_UPN=$1
  echo "Offboarding user: $USER_UPN"

  USER_ID=$(az ad user show --id $USER_UPN --query id -o tsv)

  echo "Checking group memberships..."
  az ad user get-member-groups --id $USER_ID -o table

  echo "Checking role assignments..."
  az role assignment list --assignee $USER_ID -o table

  echo "Removing all role assignments for $USER_UPN..."
  az role assignment delete --assignee $USER_ID

  echo "Revoking active sessions..."
  az ad user revoke-sign-in-sessions --id $USER_ID

  echo "Offboarding complete for $USER_UPN. Verify below:"
  az role assignment list --assignee $USER_ID -o table
}

# ==== Example test call (comment out if not testing right now) ====
# offboard_user "departeduser@victoryokpoyooutlook.onmicrosoft.com"

echo "Script finished."


