# main.tf (Finalized Dark Node Architecture)

variable "location" {
  default = "australiaeast"
}

data "azurerm_resource_group" "eth_node" {
  name = "rg-lodestar-node"
}

# ---------------------------------------------------------
# 1. Storage Configuration
# ---------------------------------------------------------
resource "azurerm_storage_account" "storage" {
  name                     = "stlodestardata499"
  resource_group_name      = data.azurerm_resource_group.eth_node.name
  location                 = data.azurerm_resource_group.eth_node.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}