To secure a **Lodestar Light Client** in **Azure Container Instance (ACI)** without using the premium Azure Firewall, you must leverage **Virtual Network (VNet) Integration** and **Network Security Groups (NSGs)**.

Since ACI instances in a VNet do not receive a public IP address by default, you will need an **Azure Load Balancer** to handle inbound traffic from your specific IP and a **NAT Gateway** to provide a stable outbound identity for the Ethereum network.

---

### 1. Required Azure Resources

* **Virtual Network (VNet):** A private network to house your client.
* **Delegated Subnet:** A subnet with the `Microsoft.ContainerInstance/containerGroups` delegation.
* **Network Security Group (NSG):** Acts as your primary filter for both inbound and outbound traffic.
* **Standard Public Load Balancer:** To provide a public entry point for your specific "End User IP."
* **NAT Gateway + Public IP:** To ensure the Ethereum network sees a consistent IP from your client and to allow outbound connectivity from the VNet.

---

### 2. Configuration Steps

#### Step A: Configure the Virtual Network & Subnet

1. Create a **VNet** (e.g., `10.0.0.0/16`).
2. Create a **Subnet** (e.g., `10.0.1.0/24`) and set **Subnet Delegation** to `Microsoft.ContainerInstance/containerGroups`.
3. Assign the **NSG** (created in Step B) to this subnet.

#### Step B: Define NSG Security Rules

The NSG is the core "firewalling" component in this setup.

**Inbound Rules (Restricting to your IP):**
| Priority | Name | Port | Protocol | Source | Action | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 100 | AllowUserAPI | 9596 | TCP | [Your Public IP] | **Allow** | Restricted access to Lodestar REST API. |
| 65000 | DenyAllInbound | Any | Any | Any | **Deny** | Blocks all other internet access. |

**Outbound Rules (Ethereum Network):**
| Priority | Name | Port | Protocol | Destination | Action | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 100 | AllowBeaconAPI | 443 | TCP | `Internet`* | **Allow** | Connects to Sepolia Beacon API (HTTPS). |
| 110 | AllowP2PGossip | 9000, 30303 | Any | `Internet` | **Allow** | Allows Ethereum P2P node communication. |
| 65000 | DenyAllOutbound | Any | Any | `Internet` | **Deny** | Blocks all other outbound internet traffic. |

> [!NOTE]
> *Because NSGs do not support FQDNs (like `lodestar-sepolia.chainsafe.io`), you must either use the `Internet` tag on the specific ports required or manually find and whitelist the IP addresses of your preferred Ethereum RPC/Beacon providers.

#### Step C: Setup Inbound & Outbound Connectivity

1. **Inbound (Load Balancer):** Create a **Standard Public Load Balancer**.
* Create a **Frontend IP** configuration with a new Public IP.
* Create a **Load Balancing Rule** mapping Public Port `9596` to Backend Port `9596`.
* Add the **Private IP** of your ACI (assigned after deployment) to the Backend Pool.


2. **Outbound (NAT Gateway):** Create a **NAT Gateway** and associate it with a Public IP.
* Attach the NAT Gateway to your ACI Subnet. This prevents the ACI from using random Azure outbound IPs, which some Ethereum nodes might throttle.



#### Step D: Deploy the Lodestar Light Client

Deploy the ACI into the delegated subnet using the `az container create` command. Ensure you specify the Sepolia network and your trusted checkpoint.

```bash
az container create \
  --resource-group MyResourceGroup \
  --name lodestar-sepolia-client \
  --image chainsafe/lodestar:latest \
  --vnet MyVNet \
  --subnet MyACISubnet \
  --command-line "lodestar lightclient --network sepolia --beaconApiUrl https://lodestar-sepolia.chainsafe.io --checkpointRoot 0xccaff4b99986a7b05e06738f1828a32e40799b277fd9f9ff069be55341fe0229" \
  --ports 9596 9000 30303

```

---

### Comparison of ACI vs. Azure Container Apps (ACA)

Based on your investigation links, **Azure Container Apps** might actually be a simpler alternative for this specific requirement:

* **Native Ingress Restrictions:** ACA allows you to set "IP Security Restrictions" directly in the portal without needing a Load Balancer or complex NSG rules.
* **Scale to Zero:** If you aren't sending transactions 24/7, ACA can scale to zero to save costs, whereas ACI remains active.

**Would you like me to draft the specific Azure CLI commands or a Bicep template to automate this entire "No Firewall" network setup?**