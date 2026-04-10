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
One container runs Lodestar, and the other runs a Tailscale sidecar.Lodestar Container: Handles P2P traffic and syncs via a checkpoint URL.Tailscale Sidecar: Creates a private, encrypted "mesh" tunnel between your ACI and your home laptop. This allows you to access the RPC port over a private IP, keeping it completely hidden from the public internet.2. Networking ConfigurationYou will expose only the essential ports to the public internet.PortTypePurposeExposure9000TCP/UDPEthereum P2P (Discovery)Public (Everyone)9596TCPLodestar REST/RPCPrivate (Localhost/Tailscale only)By not exposing port 9596 to the public IP of the ACI, you eliminate the risk of unauthorized RPC calls or DDoS attacks on your node.

3. Step-by-Step Deployment

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


### Phase 1: Bootstrapping & Identity
Build the Terraform management plane

#### Step 1.0: Create the Target Resource Group
Since the SPN will be restricted to this group, it needs to exist beforehand. Run this in your Azure Cloud Shell:

```Bash
# Set your variables
RG_NAME="rg-lodestar-node"
LOCATION="eastus" # or your preferred region

# Create the Resource Group
az group create --name $RG_NAME --location $LOCATION
```

#### Step 1.1: Azure Service Principal (SPN) Creation
Create an identity for GitHub Actions.
Now, create the SPN and restrict its "Contributor" role strictly to that group. 
NOTE: replace {subscription-id}.

```Bash
az ad sp create-for-rbac --name "github-eth-node-sp" --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-lodestar-node \
  --sdk-auth
```

Verification: After running this, go to the Azure Portal > Resource Groups > rg-lodestar-node > Access Control (IAM). You should see "github-eth-node-sp" listed with the Contributor role for the resource group.

#### Step 1.2: Terraform Backend Setup
We need a place to store the `.tfstate` for GitHub Actions to keep track of resources.
* **Action:** Create a Terraform state Storage Account inside the same Resource Group (rg-lodestar-node).
In the Azure Cloud Shell run the following commands
```bash
# 1. Generate a unique name for your storage account (must be globally unique)
# This appends a random 4-character hex string to the name
STORAGE_NAME="stethterraformstate$(openssl rand -hex 4)"
RG_NAME="rg-lodestar-node"
LOCATION="eastus"

# 2. Create the storage account inside the scoped Resource Group
az storage account create \
  --name $STORAGE_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob
  --enable-versioning true

# 3. Create the blob container for the state file
az storage container create \
  --name tfstate \
  --account-name $STORAGE_NAME

# 4. Display the name so you can copy it to your Terraform 'backend' config
echo "Your Terraform Storage Account Name is: $STORAGE_NAME"
```
Verification step
```bash
az storage account show --name $STORAGE_NAME --resource-group rg-lodestar-node --query "provisioningState"
```

---

### Phase 2: Repository & Secret Management
#### Step 2.1: Secure Tailscale Authentication

1. Create your Tailscale Account (if not already created)
- Go to tailscale.com.
- Click "Get Started for Free" or "Log in".
- Sign in using a "Single Sign-On" (SSO) provider. Tailscale doesn't use passwords; it uses your existing identity from GitHub, Google, or Microsoft.
Recommendation: Use the same GitHub account you are using for this project to keep your "DevOps" identity consistent.

2. Access the Admin Console
Once you are logged in, you will be taken to the Dashboard (this is the "Admin Console"). If you are on their homepage, there will be an "Admin Console" button in the top right corner.

3. Generate the Auth Key (The Step-by-Step)
Now that you're in the console:
- Click on the Settings tab in the top navigation bar.
- On the left-hand sidebar, click Keys.
- In the Auth keys section, click the Generate auth key... button.
- Configure the settings exactly like this:
- Description: Give it a name like azure-eth-node.
- Reusable: Check this box. Since containers in ACI might restart, you want the new container instance to be able to use the same key to re-join your network.
- Ephemeral: Check this box. This is a "cleanliness" feature. It tells Tailscale: "If this container goes offline and doesn't come back for a while, delete it from my dashboard automatically."
- Expiration: Set it to whatever you feel comfortable with (e.g., 90 days). You'll just need to update your GitHub Secret when it expires.
- Click Generate key.

4. Secure the Key
- Copy the key immediately (it starts with tskey-auth-...).
Warning: You will never see this key again once you close the pop-up.
- Action: Go straight to your GitHub Repository -> Settings -> Secrets and variables -> Actions and create a new secret named TAILSCALE_AUTH_KEY and paste the value there.



#### Step 2.2: GitHub Secrets Injection
* **Action:** Populate your GitHub Repository Secrets with:
    * `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
    * `TAILSCALE_KEY`
* **Verification:** Create a dummy GitHub Action that prints "Secrets Loaded" (do not print the actual secrets!) to ensure the environment variables are mapping correctly.
1. Create the Workflow File
In your local repository (or directly in GitHub), create a new file at this exact path:
`.github/workflows/verify-secrets.yml`

2. Add the Test Code
Paste the following configuration into that file. This workflow doesn't install anything; it just checks if the "containers" for your secrets are populated.

```yaml
name: Verify Secrets Mapping

on: 
  workflow_dispatch: # This allows you to run it manually for testing

jobs:
  test-secrets:
    runs-on: ubuntu-latest
    steps:
      - name: Check Azure Credentials
        run: |
          if [ -n "${{ secrets.AZURE_CREDENTIALS }}" ]; then
            echo "✅ AZURE_CREDENTIALS is set."
          else
            echo "❌ AZURE_CREDENTIALS is MISSING."
            exit 1
          fi

      - name: Check Tailscale Key
        run: |
          if [ -n "${{ secrets.TAILSCALE_AUTH_KEY }}" ]; then
            echo "✅ TAILSCALE_AUTH_KEY is set."
          else
            echo "❌ TAILSCALE_AUTH_KEY is MISSING."
            exit 1
          fi

      - name: Verify Secret Format (Optional)
        run: |
          # This checks if the Azure secret looks like JSON without printing the contents
          echo "${{ secrets.AZURE_CREDENTIALS }}" | grep -q "clientId" && echo "✅ Azure JSON format looks correct." || echo "⚠️ Azure Secret might not be in the correct JSON format."
```



3. Run the Verification
- **Commit and Push** this file to your GitHub repository.
- Go to the **Actions** tab at the top of your GitHub repo page.
- On the left sidebar, click on **"Verify Secrets Mapping"**.
- Click the **"Run workflow"** dropdown button on the right and hit the green button.

4. Interpreting the Results
* **Green Checkmarks:** Your environment variables are correctly mapped. You are safe to proceed to the Terraform deployment.
* **Red "X":** GitHub cannot find the secret. This usually means there is a **typo** between the name you gave the secret in the "Settings" tab and the name you used in the YAML file (e.g., `TAILSCALE_KEY` vs `TAILSCALE_AUTH_KEY`).

### Why this is "Best Practice"
GitHub automatically masks secrets in logs (replacing them with `***`). However, if you accidentally echo a secret that isn't properly recognized as a secret, you could leak it to your logs. By using the `-n` (not empty) check in a shell script, we verify the **existence** of the data without ever risking the **exposure** of the data.

---

### Phase 3: Infrastructure Deployment (The "Apply" Phase)
#### Step 3.1: Terraform Initialization
* **Action:** Trigger the GitHub Action by pushing your `main.tf` and `variables.tf`.
* **Verification:** Check the **Terraform Init** logs in GitHub Actions to ensure the backend provider (Azure Storage) connects successfully.

#### Step 3.2: Resource Provisioning
* **Action:** Run the `terraform apply`.
* **Verification:** * Navigate to the Azure Portal. 
    * Verify the **Resource Group** exists.
    * Confirm the **Azure File Share** is created (this is critical for Lodestar's persistent database).

---

### Phase 4: Container Orchestration & Networking
#### Step 4.1: Sidecar Initialization (Tailscale)
Once ACI starts, the Tailscale container must join your "Tailnet."
* **Action:** Monitor the Tailscale Admin Console.
* **Verification:** A new machine (e.g., `lodestar-light-node`) should appear in your Tailscale dashboard with a **100.x.y.z** IP address.

#### Step 4.2: Lodestar Startup & Checkpoint Sync
The Lodestar container will start and attempt to sync using the `checkpointSyncUrl`.
* **Action:** Use the Azure CLI to stream logs:
    ```bash
    az container logs --resource-group rg-lodestar-node --name lodestar-light-node --container-name lodestar
    ```
* **Verification:** Look for the log line: `Verified transition to new sync committee`. This confirms the light client has successfully performed the "Weak Subjectivity" handshake.

---

### Phase 5: Final Validation & Connectivity
#### Step 5.1: The "Private Tunnel" Test
Now we verify that the RPC port (9596) is truly private but accessible to you.
* **Action:** On your local laptop (with Tailscale running), run a CURL command against the **Tailscale IP**:
    ```bash
    curl http://<Tailscale-IP>:9596/eth/v1/beacon/genesis
    ```
* **Verification:** You should receive a JSON response containing the Ethereum Genesis data.

#### Step 5.2: Public Port Scan (Security Audit)
* **Action:** Find the **Public IP** of your ACI in the Azure Portal. Use `nmap` or an online port scanner.
* **Verification:**
    * **Port 9000 (TCP/UDP):** Should be **Open** (required for P2P).
    * **Port 9596 (TCP):** Should be **Filtered/Closed** (successfully hidden by your architecture).

---

### Engineering Observations & Tips
* **Resource Throttling:** You allocated `0.5 CPU` to Lodestar. During the initial header sync, you might see 100% usage. If the container restarts frequently (OOM Killed), consider bumping memory to `1.5GB`.
* **Storage Performance:** Since you are using a Standard LRS File Share, the IOPS are limited. For a Light Client, this is fine. However, if you see "Database Timeout" in the logs, it’s likely the SMB latency.
* **Tailscale ACLs:** In your Tailscale dashboard, I recommend setting an ACL to only allow *your* specific laptop tag to talk to the node tag on port 9596.

This plan moves you from a static design to a living, breathing node. Ready to push the first commit?