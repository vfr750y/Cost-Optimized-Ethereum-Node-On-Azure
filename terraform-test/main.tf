# main.tf (Finalized Ethereum Node Architecture)
variable "location" {
  default = "australiaeast"
}

variable "tailscale_key" {
  description = "Tailscale Auth Key"
  type        = string
  sensitive   = true
}

variable "infura_url" {
  description = "Execution Layer RPC URL (Infura/Alchemy)"
  type        = string
}

variable "log_analytics_workspace" {
  description = "Log analytics workspace for container logging"
  type = string
}

data "azurerm_resource_group" "eth_node" {
  name = "rg-lodestar-node"
}

data "azurerm_log_analytics_workspace" "lodestar_logs" { 
  name = var.log_analytics_workspace
  resource_group_name = data.azurerm_resource_group.eth_node.name 
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
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 10
}

# Separate share for Tailscale state (identity/keys)
resource "azurerm_storage_share" "tailscale_share" {
  name                 = "tailscale-state"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 1
}

# ---------------------------------------------------------
# 2. Container Group (The Lodestar Light Node)
# ---------------------------------------------------------
resource "azurerm_container_group" "node_group" {
  name                = "lodestar-light-node"
  location            = data.azurerm_resource_group.eth_node.location
  resource_group_name = data.azurerm_resource_group.eth_node.name
  os_type             = "Linux"
  ip_address_type     = "None" # No Public IP
  restart_policy = "Always"
  diagnostics { 
    log_analytics { 
      workspace_id = data.azurerm_log_analytics_workspace.lodestar_logs.workspace_id 
      workspace_key = data.azurerm_log_analytics_workspace.lodestar_logs.primary_shared_key 
    } 
  }

  # --- Lodestar Light Client ---
  container {
    name   = "lodestar"
    image  = "chainsafe/lodestar:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 9596
      protocol = "TCP"
    }

commands = [
  "/bin/sh", "-c", 
  "find / -name lodestar 2>/dev/null && find / -name '*.js' 2>/dev/null | grep lodestar && sleep 3600" 
]

#commands = [
#  "/bin/sh",
#  "-c",
#  <<-EOT
#    /usr/local/bin/lodestar lightclient \
#      --network sepolia \
#      --beaconApiUrl https://lodestar-sepolia.chainsafe.io \
#      --checkpointRoot 0xccaff4b99986a7b05e06738f1828a32e40799b277fd9f9ff069be55341fe0229 \
#      --dataDir /data \
#      --logLevel info \
#      --rest \
#      --rest.address 0.0.0.0 \
#      --rest.port 9596 \
#      --persistNetworkIdentity false
#  EOT
#]

    volume {
      name                 = "lodestar-storage"
      mount_path           = "/data"
      share_name           = azurerm_storage_share.lodestar_share.name
      storage_account_name = azurerm_storage_account.storage.name
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
    }
  }

  # --- Lodestar Prover Proxy ---
# container {
#  name   = "prover"
#  image  = "chainsafe/lodestar:latest"
#  cpu    = "0.5"
#  memory = "1.0"
#  
#  ports {
#    port     = 8080
#    protocol = "TCP"
#  }

#commands = [
#  "/bin/sh", "-c",
#  "/usr/local/bin/lodestar prover proxy --network sepolia --executionRpcUrl ${var.infura_url} --beaconUrls http://127.0.0.1:9596 --port 8080 --address 0.0.0.0 --logLevel debug"
#]

#}

  container {
    name   = "tailscale"
    image  = "tailscale/tailscale:latest"
    cpu    = "0.5"
    memory = "0.5"

    environment_variables = {
      TS_AUTHKEY    = var.tailscale_key
      TS_STATE_DIR  = "/var/lib/tailscale"
      TS_USERSPACE  = "true" # Mandatory for ACI
      TS_EXTRA_ARGS = "--hostname=eth-light-node --accept-dns=false"
    }

    volume {
      name                 = "tailscale-state"
      mount_path           = "/var/lib/tailscale"
      share_name           = azurerm_storage_share.tailscale_share.name
      storage_account_name = azurerm_storage_account.storage.name
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
    }
  }
}