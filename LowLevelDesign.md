# Low level design

## GitHub Repository Structure


```Plaintext
.
├── .github/workflows/deploy.yml  # GitHub Actions CI/CD
├── main.tf                       # Terraform: ACI, Storage, and Logic
├── variables.tf                  # Variable definitions
├── outputs.tf                    # IP and Connection info
└── providers.tf                  # Azure provider config

```


## Terraform Configuration (main.tf)

This configuration uses a Multi-Container Group. Lodestar runs the node, and Tailscale provides the secure tunnel for your laptop. We use Azure Files to persist the node state and Tailscale's identity.

```Terraform
# main.tf

resource "azurerm_resource_group" "eth_node" {
  name     = "rg-lodestar-node"
  location = var.location
}

# Storage for Node Sync State & Tailscale Auth
resource "azurerm_storage_account" "storage" {
  name                     = "stlodestardata${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.eth_node.name
  location                 = azurerm_resource_group.eth_node.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Lowest cost
}

resource "azurerm_storage_share" "lodestar_share" {
  name                 = "lodestar-data"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 5 # 5GB is plenty for a light node
}

# The Container Group
resource "azurerm_container_group" "node_group" {
  name                = "lodestar-light-node"
  location            = azurerm_resource_group.eth_node.location
  resource_group_name = azurerm_resource_group.eth_node.name
  os_type             = "Linux"
  ip_address_type     = "Public" # Required for P2P Discovery
  dns_name_label      = "lodestar-node-${random_string.suffix.result}"

  # Container 1: Lodestar
  container {
    name   = "lodestar"
    image  = "chainsafe/lodestar:latest"
    cpu    = "0.5"
    memory = "1.0"

    commands = [
      "node", "light-client",
      "--network", "mainnet",
      "--checkpointSyncUrl", "https://beaconstate.ethpandaops.io/",
      "--rest",
      "--rest.address", "0.0.0.0",
      "--rest.port", "9596",
      "--rootDir", "/data"
    ]

    ports {
      port     = 9000
      protocol = "TCP"
    }
    ports {
      port     = 9000
      protocol = "UDP"
    }

    volume {
      name                 = "lodestar-storage"
      mount_path           = "/data"
      share_name           = azurerm_storage_share.lodestar_share.name
      storage_account_name = azurerm_storage_account.storage.name
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
    }
  }

  # Container 2: Tailscale Sidecar
  container {
    name   = "tailscale"
    image  = "tailscale/tailscale:latest"
    cpu    = "0.1"
    memory = "0.2"

    environment_variables = {
      TS_AUTHKEY   = var.tailscale_key
      TS_STATE_DIR = "/var/lib/tailscale"
    }

    volume {
      name                 = "tailscale-state"
      mount_path           = "/var/lib/tailscale"
      share_name           = azurerm_storage_share.lodestar_share.name
      storage_account_name = azurerm_storage_account.storage.name
      storage_account_key  = azurerm_storage_account.storage.primary_access_key
    }
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
```

## GitHub Actions Workflow (deploy.yml)
To automate this, you will store your Azure credentials and Tailscale key in GitHub Secrets.

Azure Service Principal: Create one using az ad sp create-for-rbac and save the JSON as AZURE_CREDENTIALS.

Tailscale Key: Create an Auth Key (reusable recommended) in your Tailscale dashboard and save as TAILSCALE_KEY.
```yaml
YAML
name: Deploy Lodestar Node

on:
  push:
    branches: [ main ]

jobs:
  terraform:
    runs-on: ubuntu-latest
    env:
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init

      - name: Terraform Apply
        run: terraform apply -auto-approve \
          -var="tailscale_key=${{ secrets.TAILSCALE_KEY }}"
```

## Azure container instance details
One container runs Lodestar, and the other runs a Tailscale sidecar.Lodestar Container: Handles P2P traffic and syncs via a checkpoint URL.Tailscale Sidecar: Creates a private, encrypted "mesh" tunnel between your ACI and your home laptop. This allows you to access the RPC port over a private IP, keeping it completely hidden from the public internet.2. Networking ConfigurationYou will expose only the essential ports to the public internet.PortTypePurposeExposure9000TCP/UDPEthereum P2P (Discovery)Public (Everyone)9596TCPLodestar REST/RPCPrivate (Localhost/Tailscale only)By not exposing port 9596 to the public IP of the ACI, you eliminate the risk of unauthorized RPC calls or DDoS attacks on your node.3. Step-by-Step Deployment

Step A: Setup Persistence (Azure Files)Even a light node needs to save its "head" and sync state, or it will start from scratch every time the container restarts.Create a Standard LRS Storage Account (cheapest tier).Create a File Share (e.g., lodestar-data).

Step B: Create the Deployment YAMLACI is best managed via a YAML file when using sidecars. Create a file named deploy-lodestar.yaml.

```yaml
YAMLapi-version: 2023-05-01
location: eastus # Or your closest region
name: lodestar-light-node
type: Microsoft.ContainerInstance/containerGroups
properties:
  containers:
  - name: lodestar
    properties:
      image: chainsafe/lodestar:latest
      command: 
      - node
      - light-client
      - --network
      - mainnet
      - --checkpointSyncUrl
      - https://beaconstate.ethpandaops.io/ # Use a trusted community sync URL
      - --rest
      - --rest.address
      - 0.0.0.0
      - --rest.port
      - "9596"
      - --rootDir
      - /data
      resources:
        requests:
          cpu: 1.0
          memoryInGB: 2.0
      volumeMounts:
      - name: lodestar-storage
        mountPath: /data
  - name: tailscale # The security sidecar
    properties:
      image: tailscale/tailscale:latest
      environmentVariables:
      - name: TS_AUTHKEY
        value: "tskey-auth-your-key-here" # Get this from tailscale.com
      - name: TS_STATE_DIR
        value: /var/lib/tailscale
      resources:
        requests:
          cpu: 0.5
          memoryInGB: 0.5
  osType: Linux
  ipAddress:
    type: Public
    ports:
    - protocol: TCP
      port: 9000
    - protocol: UDP
      port: 9000
  volumes:
  - name: lodestar-storage
    azureFile:
      shareName: lodestar-data
      storageAccountName: yourstorageaccount
      storageAccountKey: yourstoragekey
```

Step C: Deploy via Azure CLI
Run the following command in your terminal:Bashaz container create --resource-group YourRG --file deploy-lodestar.yaml
4. How to Connect from Your LaptopInstall Tailscale on your laptop.Once the ACI is running, it will appear in your Tailscale dashboard as a "machine" with a private IP (e.g., 100.x.y.z).On your laptop, simply point your dApp or script to:http://100.x.y.z:9596
Why this is safe: Only devices authenticated to your Tailscale account can "see" the RPC port. To the rest of the world, your ACI only looks like a standard Ethereum peer on port 9000.