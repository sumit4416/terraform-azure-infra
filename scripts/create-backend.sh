#!/usr/bin/env bash
# Terraform remote state ke liye Azure Storage Account + Blob container banata hai.
# Ye ek baar chalana hai, Terraform apply se PEHLE.
set -euo pipefail

LOCATION="${LOCATION:-centralindia}"
RG_NAME="${RG_NAME:-tfstate-rg}"
SA_NAME="${SA_NAME:-tfstate$RANDOM$RANDOM}"   # globally unique, lowercase, 3-24 chars
CONTAINER="${CONTAINER:-tfstate}"

echo ">> Resource group: $RG_NAME"
az group create --name "$RG_NAME" --location "$LOCATION" --output none

echo ">> Storage account: $SA_NAME"
az storage account create \
  --name "$SA_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none

echo ">> Blob container: $CONTAINER"
az storage container create \
  --name "$CONTAINER" \
  --account-name "$SA_NAME" \
  --auth-mode login \
  --output none

cat > backend.hcl <<EOF
resource_group_name  = "$RG_NAME"
storage_account_name = "$SA_NAME"
EOF

echo ">> Done. backend.hcl ban gaya:"
cat backend.hcl
echo ">> Ab chalao: terraform init -backend-config=backend.hcl"
