
#!/bin/bash
set -e

# ==== Configuration ====
RESOURCE_GROUP="rg-verdantpay-iam"
LOCATION="southafricanorth"
VNET_NAME="vnet-verdantpay"
SUBSCRIPTION_ID="f6a1c9ee-95ed-4bbb-9f16-e72d2dad5499"

WEBADMINS_GROUP="WebAdmins"
INTERNS_GROUP="Interns"
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

echo "Creating Interns group..."
az ad group create --display-name $INTERNS_GROUP --mail-nickname $INTERNS_GROUP

echo "Creating DBAdmins group..."
az ad group create --display-name $DBADMINS_GROUP --mail-nickname $DBADMINS_GROUP

# ==== Test User Provisioning (2 Intern Users) ====
DOMAIN=$(az rest --method get --url "https://graph.microsoft.com/v1.0/domains" --query "value[0].id" -o tsv)

echo "Creating intern test user 1..."
if az ad user show --id "internuser1@$DOMAIN" &> /dev/null; then
  echo "InternTestUser1 already exists, skipping creation."
else
  az ad user create --display-name "InternTestUser1" --user-principal-name "internuser1@$DOMAIN" --password TempPass123X9Zq --force-change-password-next-sign-in true
fi

echo "Creating intern test user 2..."
if az ad user show --id "internuser2@$DOMAIN" &> /dev/null; then
  echo "InternTestUser2 already exists, skipping creation."
else
  az ad user create --display-name "InternTestUser2" --user-principal-name "internuser2@$DOMAIN" --password TempPass123X9Zq --force-change-password-next-sign-in true
fi

sleep 15

INTERN1_ID=$(az ad user show --id "internuser1@$DOMAIN" --query id -o tsv)
INTERN2_ID=$(az ad user show --id "internuser2@$DOMAIN" --query id -o tsv)

echo "Adding intern users to $INTERNS_GROUP..."
az ad group member add --group $INTERNS_GROUP --member-id $INTERN1_ID 2>/dev/null || echo "Intern 1 already in group, skipping."
az ad group member add --group $INTERNS_GROUP --member-id $INTERN2_ID 2>/dev/null || echo "Intern 2 already in group, skipping."
echo "Intern users check complete for $INTERNS_GROUP."

# ==== Role Assignments ====
WEBADMINS_ID=$(az ad group show --group $WEBADMINS_GROUP --query id -o tsv)
INTERNS_ID=$(az ad group show --group $INTERNS_GROUP --query id -o tsv)
DBADMINS_ID=$(az ad group show --group $DBADMINS_GROUP --query id -o tsv)

# Subnet Resource IDs
WEB_SUBNET_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-web"
DB_SUBNET_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-db"

echo "Assigning Contributor to WebAdmins on Web Subnet..."
az role assignment create \
  --assignee "$WEBADMINS_ID" \
  --role "Contributor" \
  --scope "$WEB_SUBNET_ID"

echo "Assigning Contributor to Interns group on Web Subnet..."
az role assignment create \
  --assignee "$INTERNS_ID" \
  --role "Contributor" \
  --scope "$WEB_SUBNET_ID"

echo "Assigning Reader to DBAdmins on DB Subnet..."
az role assignment create \
  --assignee "$DBADMINS_ID" \
  --role "Reader" \
  --scope "$DB_SUBNET_ID"
  
echo "Deployment complete."

# ==== Offboarding Function ====
offboard_user() {
  set +e
  USER_UPN=$1
  echo "Offboarding user: $USER_UPN"

  USER_ID=$(az ad user show --id $USER_UPN --query id -o tsv)

  echo "Checking group memberships..."
  az ad user get-member-groups --id $USER_ID -o table

  echo "Checking role assignments..."
  az role assignment list --assignee $USER_ID -o table

  echo "Removing user from all Azure AD groups..."
GROUPS=$(az ad user get-member-groups --id $USER_ID --query "[].id" -o tsv 2>/dev/null)
if [ -z "$GROUPS" ]; then
  echo "User is not a member of any groups. Nothing to remove."
else
  for GROUP_ID in $GROUPS; do
    az ad group member remove --group $GROUP_ID --member-id $USER_ID 2>/dev/null || echo "Already removed from group $GROUP_ID, skipping."
  done
fi

 echo "Removing direct role assignments for $USER_UPN..."
 az role assignment delete --assignee $USER_ID 2>/dev/null || echo "No direct role assignments found, skipping."

  echo "Disabliing Azure AD account..."
  az ad user update --id $USER_ID --account-enabled false

  echo "Offboarding complete for $USER_UPN. Verify below:"
  az role assignment list --assignee $USER_ID -o table
  echo "Account enabled status:"
  az ad user show --id $USER_ID --query accountEnabled -o tsv
    set -e
}

# ==== Example test call (comment out if not testing right now) ====
  offboard_user "departeduser@victoryokpoyooutlook.onmicrosoft.com"

echo "Script finished."
