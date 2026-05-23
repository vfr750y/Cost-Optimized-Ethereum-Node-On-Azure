# 🚀 Cost-Optimized Ethereum Node on Azure

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Provider: Azure](https://img.shields.io/badge/Provider-Azure-blue)](https://azure.microsoft.com/)
[![IaC: Terraform](https://img.shields.io/badge/IaC-Terraform-purple)](https://www.terraform.io/)

Managed node providers (Infura, Alchemy, QuickNode) are excellent but expensive at scale. This project provides a **production-ready framework** to host your own Ethereum Light Nodes on Azure for a fraction of the cost.

### 💰 Estimated Monthly Infrastructure Costs (Azure 2026)

This project leverages **Azure Container Instances (ACI)** to provide a serverless, "pay-as-you-go" infrastructure. By avoiding dedicated VMs and using Tailscale for private networking, we eliminate the need for expensive Load Balancers and Public IPs. **The costs shown below are for 100% utilization.** The light node containerised Azure resources can be deployed when neeeded using the latest checkpoint block route to avoid startup overheads for CPU and data transfer. Stop the container group to stop billing.

| Resource Component        | Minimum (Low Traffic) | Maximum Monthly Cost | Recommended (Production) | Maximum Monthly Cost |
| :------------------------ | :-------------------- | :----------- | :----------------------- | :------------------- |
| **Compute (vCPU)**        | 1 vCPU Total          | ~$30         | 1.75 vCPU Total          | ~$58         |
| **Memory (RAM)**          | 1.5 GiB Total         | ~$6          | 3.5 GiB Total            | ~$11         |
| **Storage (Azure Files)** | 32 GB Standard Hot    | ~$5          | 32 GB Standard Hot       | ~$5          |
| **Networking**            | Tailscale             | $0.00        | Tailscale | $0.00        |
| **Estimated Total** (USD) | **max daily: ~$1.20** | **$41   **   | **Daily: ~$2.60**        | **$74**      |


### 💡 Why This Architecture?
* **Zero Idle Waste:** ACI bills per-second of usage. If you stop the containers, you stop the billing.
* **No "Cloud Tax":** Bypassing Public IPs and Load Balancers saves ~$25-$40/month in standard Azure networking fees.
* **Lodestar Optimized:** Uses the TypeScript-based Lodestar client, specifically tuned for low-memory environments like containers.
* **Privacy First:** Traffic remains within your private Tailscale network, invisible to the public internet and protected from ISP/Cloud provider snooping.

```mermaid
graph TB
    subgraph Client_Env [Local Environment]
        Wallet((MetaMask))
        TS_App[Tailscale Client]
    end

    subgraph Azure ["Azure Subscription (No VNet/No NSG)"]
        direction TB
        
        subgraph ACI_Group ["ACI Container Group (Public IP: None)"]
            direction LR
            Lodestar["Lodestar Light Client"]
            Prover["Lodestar Prover"]
            Tailscale["Tailscale Sidecar"]
        end

        FS[("Azure File Share: Persistent Data")]
    end

    %% Networking
    Wallet --> TS_App
    TS_App == "WireGuard Tunnel" ==> Tailscale
    Tailscale -. "Localhost" .-> Prover
    Prover -- "Outbound Only" --> Web3((Web3Provider))
    Tailscale -. "Localhost" .-> Lodestar
    Lodestar -- "Outbound Only" --> Eth_Network((Ethereum P2P))
    Lodestar -- "Mount" --> FS
```

## 🌟 Business Value & Key Features
*   **Cost Reduction:** Leverage Azure container instances and Light Node sync modes to cut costs by 60-80%.
*   **Infrastructure as Code (IaC):** 100% automated deployment via Terraform—no manual configuration errors.
*   **Full Data Sovereignty:** Own your RPC endpoints. No rate limits, no third-party tracking.
*   **Enterprise-Ready:** Built-in support for Azure Key Vault (Security) and Resource Groups (Organization).

## 🛠 Tech Stack
*   **Cloud:** Microsoft Azure
*   **Provisioning:** Terraform
*   **Blockchain:** Ethereum Mainnet / Sepolia
*   **Connectivity:** Tailscale

---

## 🚀 Deployment in 3 Steps
1. **Clone & Initialize:** `git clone ... && terraform init`
2. **Configure:** Update TF_VARIABLEs with your Azure Subscription ID.
3. **Deploy:** `terraform apply`

---

## 💼 Need a Custom Solution? 
I specialize in helping Enterprises scale their infrastructure while minimizing cloud spend. 
[**Hire me on Upwork for your Web3 DevOps needs**]

## Further documentation

### [1) Project plan](ProjectPlan.md)
### [2) Requirements Analysis](RequirementsAnalysis.md)
### [3) High level design](HighLevelDesign.md)
### [4) Low level design](LowLevelDesign.md)
### [5) Implementation](AsBuilt.md)
### [6) Project de-brief ]()






