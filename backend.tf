# Remote state Azure Blob Storage me store hota hai.
# Baaki values (resource group, storage account) backend.hcl se aati hain:
#   terraform init -backend-config=backend.hcl
terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key            = "azure-infra.terraform.tfstate"
  }
}
