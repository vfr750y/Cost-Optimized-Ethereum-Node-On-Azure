terraform {
  backend "azurerm" {
    resource_group_name  = "rg-lodestar-node"
    storage_account_name = "stethterraformstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}