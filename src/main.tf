# main.tf (Finalized Dark Node Architecture)

resource "azurerm_resource_group" "eth_node" {
  name     = "rg-lodestar-node"
  location = var.location
}

# ---------------------------------------------------------
# 1. Storage Configuration
# ---------------------------------------------------------
resource "azurerm_storage_account" "storage" {
  name                     = "stlodestardata${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.eth_node.name
  location                 = azurerm_resource_group.eth_node.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}