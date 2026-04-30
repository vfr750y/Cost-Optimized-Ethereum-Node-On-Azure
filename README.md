# 🚀 Cost-Optimized Ethereum Node on Azure

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Provider: Azure](https://img.shields.io/badge/Provider-Azure-blue)](https://azure.microsoft.com/)
[![IaC: Terraform](https://img.shields.io/badge/IaC-Terraform-purple)](https://www.terraform.io/)

### 💰 Stop Overpaying for Web3 Infrastructure
Managed node providers (Infura, Alchemy, QuickNode) are excellent but expensive at scale. This project provides a **production-ready framework** to host your own Ethereum Light Nodes on Azure for a fraction of the cost.

### 💰 Estimated Monthly Infrastructure Costs (Azure 2026)

This project leverages **Azure Container Instances (ACI)** to provide a serverless, "pay-as-you-go" infrastructure. By avoiding dedicated VMs and using **Tailscale** for private networking, we eliminate the need for expensive Load Balancers and Public IPs.

| Resource Component        | Minimum (Low Traffic) | Monthly Cost | Recommended (Production) | Monthly Cost |
| :------------------------ | :-------------------- | :----------- | :----------------------- | :----------- |
| **Compute (vCPU)**        | 0.85 vCPU Total       | ~$30.15      | 1.75 vCPU Total          | ~$62.10      |
| **Memory (RAM)**          | 1.6 GiB Total         | ~$6.30       | 3.5 GiB Total            | ~$13.80      |
| **Storage (Azure Files)** | 50 GB Standard Hot    | ~$1.00       | 100 GB Standard Hot      | ~$2.00       |
| **Networking**            | Private VNet + Tailscale | $0.00     | Private VNet + Tailscale | $0.00        |
| **Estimated Total**       | **Daily: ~$1.25**     | **$37.45**   | **Daily: ~$2.60**        | **$77.90**   |

---

### 📊 Competitive Comparison

| Provider | Service Tier | Monthly Cost | Savings with this Repo |
| :--- | :--- | :--- | :--- |
| **Infura** | Growth Tier | $299.00+ | **~74% Savings** |
| **Alchemy** | Growth Tier | $199.00+ | **~61% Savings** |
| **This Solution** | **Production (Azure)** | **$77.90** | **100% Data Ownership** |

---

### 💡 Why This Architecture?
* **Zero Idle Waste:** ACI bills per-second of usage. If you stop the containers, you stop the billing.
* **No "Cloud Tax":** Bypassing Public IPs and Load Balancers saves ~$25-$40/month in standard Azure networking fees.
* **Lodestar Optimized:** Uses the TypeScript-based Lodestar client, specifically tuned for low-memory environments like containers.
* **Privacy First:** Traffic remains within your private Tailscale network, invisible to the public internet and protected from ISP/Cloud provider snooping.

## 🌟 Business Value & Key Features
*   **Cost Reduction:** Leverage Azure's B-Series VMs and Light Node sync modes to cut costs by 60-80%.
*   **Infrastructure as Code (IaC):** 100% automated deployment via Terraform—no manual configuration errors.
*   **Full Data Sovereignty:** Own your RPC endpoints. No rate limits, no third-party tracking.
*   **Enterprise-Ready:** Built-in support for Azure Key Vault (Security) and Resource Groups (Organization).

## 🛠 Tech Stack
*   **Cloud:** Microsoft Azure
*   **Provisioning:** Terraform
*   **Blockchain:** Ethereum Mainnet / Sepolia

---

## 🚀 Deployment in 3 Steps
1. **Clone & Initialize:** `git clone ... && terraform init`
2. **Configure:** Update `variables.tf` with your Azure Subscription ID.
3. **Deploy:** `terraform apply`

---

## 💼 Need a Custom Solution? 
I specialize in helping Enterprises scale their infrastructure while minimizing cloud spend. 
* **Custom AI Agents:** I can integrate AI agents to analyze your node traffic and Etherscan data for real-time insights.

[**Hire me on Upwork for your Web3 DevOps needs**]

## Overview of project

### Basic concept
This project deploys an Ethererum node on Azure using version control (GitHub) to manage the development and Infrastructure as Code (Terraform) to deploy and configure the relevant Azure resources. Building an Ethereum node on Azure invoives connecting a compute resource with the node software installed and running on it to the internet and the Ethereum node mesh. Additionally a secure private connection is required for administration. An initial look at [Mastering Ethereum e-book](https://masteringethereum.xyz/) shows that a full node has 2 core components to install, the execution client and the consensus client. There are also 2 sets of network ports to consider, the external Peer-to-Peer (P2P) ports and the internal admin ports. The main onstraints for the project are costs and security.
 
### Costs
The budget for this project is restricted, so at each stage of this project I'll be looking carefully at costs in Azure and finding ways to minimise them. If it's not feasible to do a full node then there are a couple of other node types to consider that might be more feasible. A Sepolia test node is also going to be cheaper than a full node. I'll compare standard VM vs Containerisation.

Initial estimate

### Security
I need to make sure that the system is secure. I'm thinking of using a basic VNET with Network Security Group (NSG) network architecture. I want to take a look at the network ports that are required and also to get an idea of the costs for data ingress and egress. 

## Project stages
The following are the basic stages for this project.

### [1) Project plan](ProjectPlan.md)
### [2) Requirements Analysis](RequirementsAnalysis.md)
### [3) High level design](HighLevelDesign.md)
### [4) Low level design](LowLevelDesign.md)
### [5) Implementation](AsBuilt.md)
### [6) Project de-brief ]()






