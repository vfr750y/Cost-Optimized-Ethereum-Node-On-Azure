# Low level design

    - Detailed description of component configuration
    - Sequence diagrams for protocol interactions
    - Detailed breakdown of costs
    - Detailed description of security risks and mitigations
    - Detailed implementation steps
    - Detailed testing procedure

## Detailed component description
### GitHub Repository Structure


```Plaintext
.
├── .github/workflows/deploy.yml  # GitHub Actions CI/CD
├── main.tf                       # Terraform: ACI, Storage, and Logic
├── variables.tf                  # Variable definitions
├── outputs.tf                    # IP and Connection info
└── providers.tf                  # Azure provider config

```


### Terraform Configuration (main.tf)

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

### GitHub Actions Workflow (deploy.yml)
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

### Azure container instance details
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

## Sequence diagrams for protocol interactions
## Detailed breakdown of costs
## Detailed description of security risks and mitigations

## Detailed implementation steps


## Phase 1: Bootstrapping & Identity
Build the Terraform management plane

### Step 1.1: Azure Service Principal (SPN) Creation
Create an identity for GitHub Actions.
* **Action:** Run the following CLI command to create an SPN with "Contributor" rights at the Subscription level.
    ```bash
    az ad sp create-for-rbac --name "github-eth-node-sp" --role contributor \
      --scopes /subscriptions/{subscription-id} --sdk-auth
    ```
* **Verification:** Ensure the output JSON is saved. Test it locally by running `az login --service-principal -u <appId> -p <password> --tenant <tenantId>`.

### Step 1.2: Terraform Backend Setup
We need a place to store the `.tfstate` so GitHub Actions doesn't lose track of your resources.
* **Action:** Manually create one "Bootstrap" Storage Account and a container named `tfstate`.
* **Verification:** Run `az storage blob list --account-name <name> --container-name tfstate` to ensure it is reachable.

---

## Phase 2: Repository & Secret Management
### Step 2.1: Secure Tailscale Authentication
* **Action:** Go to your Tailscale Admin Console and generate an **Auth Key**. Ensure it is marked as **Reusable** and **Ephemeral** (since containers might restart).
* **Verification:** Keep the key ready for the next step.

### Step 2.2: GitHub Secrets Injection
* **Action:** Populate your GitHub Repository Secrets with:
    * `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
    * `TAILSCALE_KEY`
* **Verification:** Create a dummy GitHub Action that prints "Secrets Loaded" (do not print the actual secrets!) to ensure the environment variables are mapping correctly.

---

## Phase 3: Infrastructure Deployment (The "Apply" Phase)
### Step 3.1: Terraform Initialization
* **Action:** Trigger the GitHub Action by pushing your `main.tf` and `variables.tf`.
* **Verification:** Check the **Terraform Init** logs in GitHub Actions to ensure the backend provider (Azure Storage) connects successfully.

### Step 3.2: Resource Provisioning
* **Action:** Run the `terraform apply`.
* **Verification:** * Navigate to the Azure Portal. 
    * Verify the **Resource Group** exists.
    * Confirm the **Azure File Share** is created (this is critical for Lodestar's persistent database).

---

## Phase 4: Container Orchestration & Networking
### Step 4.1: Sidecar Initialization (Tailscale)
Once ACI starts, the Tailscale container must join your "Tailnet."
* **Action:** Monitor the Tailscale Admin Console.
* **Verification:** A new machine (e.g., `lodestar-light-node`) should appear in your Tailscale dashboard with a **100.x.y.z** IP address.

### Step 4.2: Lodestar Startup & Checkpoint Sync
The Lodestar container will start and attempt to sync using the `checkpointSyncUrl`.
* **Action:** Use the Azure CLI to stream logs:
    ```bash
    az container logs --resource-group rg-lodestar-node --name lodestar-light-node --container-name lodestar
    ```
* **Verification:** Look for the log line: `Verified transition to new sync committee`. This confirms the light client has successfully performed the "Weak Subjectivity" handshake.

---

## Phase 5: Final Validation & Connectivity
### Step 5.1: The "Private Tunnel" Test
Now we verify that the RPC port (9596) is truly private but accessible to you.
* **Action:** On your local laptop (with Tailscale running), run a CURL command against the **Tailscale IP**:
    ```bash
    curl http://<Tailscale-IP>:9596/eth/v1/beacon/genesis
    ```
* **Verification:** You should receive a JSON response containing the Ethereum Genesis data.

### Step 5.2: Public Port Scan (Security Audit)
* **Action:** Find the **Public IP** of your ACI in the Azure Portal. Use `nmap` or an online port scanner.
* **Verification:**
    * **Port 9000 (TCP/UDP):** Should be **Open** (required for P2P).
    * **Port 9596 (TCP):** Should be **Filtered/Closed** (successfully hidden by your architecture).

---

## Engineering Observations & Tips
* **Resource Throttling:** You allocated `0.5 CPU` to Lodestar. During the initial header sync, you might see 100% usage. If the container restarts frequently (OOM Killed), consider bumping memory to `1.5GB`.
* **Storage Performance:** Since you are using a Standard LRS File Share, the IOPS are limited. For a Light Client, this is fine. However, if you see "Database Timeout" in the logs, it’s likely the SMB latency.
* **Tailscale ACLs:** In your Tailscale dashboard, I recommend setting an ACL to only allow *your* specific laptop tag to talk to the node tag on port 9596.

This plan moves you from a static design to a living, breathing node. Ready to push the first commit?