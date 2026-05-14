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

# Separate share for Ethereum chain data
resource "azurerm_storage_share" "lodestar_share" {
  name                 = "lodestar-data"
  storage_account_name = data.azurerm_storage_account.storage.name
  quota                = 10
}

# Separate share for Tailscale state (identity/keys)
resource "azurerm_storage_share" "tailscale_share" {
  name                 = "tailscale-state"
  storage_account_name = data.azurerm_storage_account.storage.name
  quota                = 1
}
