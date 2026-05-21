# main.tf (Finalized Ethereum Node Architecture)
variable "location" {
  default = "australiaeast"
}

variable "tailscale_key" {
  description = "Tailscale Auth Key"
  type        = string
  sensitive   = true
}

#variable "infura_url" {
#  description = "Execution Layer RPC URL (Infura/Alchemy)"
#  type        = string
#}

variable "log_analytics_workspace" {
  description = "Log analytics workspace for container logging"
  type = string
}

variable "checkpoint_root" {
  description = "Block root for recent sepolia checkpoint"
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
    cpu    = "1.0"
    memory = "2.0"
    
    ports {
      port     = 9596
      protocol = "TCP"
    }

    commands = [
      "/bin/sh", "-c",
      <<-EOT
        exec node /usr/app/packages/cli/bin/lodestar.js lightclient \
          --network sepolia \
          --beaconApiUrl https://lodestar-sepolia.chainsafe.io \
          --checkpointRoot ${var.checkpoint_root} \
          --dataDir /data \
          --logFile /dev/stdout \
          --logFileLevel verbose \
          --logLevel verbose
      EOT
  ]
    
    volume {
      name                 = "lodestar-storage"
      mount_path           = "/data"
      share_name           = azurerm_storage_share.lodestar_share.name
      storage_account_name = azurerm_storage_account.storage.name
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
    }
  }

# --- Lodestar Prover Execution Proxy ---
container {
  name   = "prover"
  image  = "chainsafe/lodestar:latest"
  cpu    = "0.5"
  memory = "1.0"

  ports {
    port     = 8080
    protocol = "TCP"
  }

  commands = [
    "/bin/sh", "-c",
    <<-EOT
      echo "Starting Lodestar Prover as a standalone proxy..." && \
      exec node /usr/app/packages/prover/bin/lodestar-prover.js proxy \
        --network sepolia \
        --executionRpcUrl https://lodestar-sepoliarpc.chainsafe.io \
        --beaconUrls https://lodestar-sepolia.chainsafe.io \
        --port 8080 \
        --logLevel verbose
    EOT
  ]
}


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