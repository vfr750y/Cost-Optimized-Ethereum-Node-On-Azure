# Ethereum Node on Azure
## Overview of project

### Basic concept
This project is a proof of concept (POC). The aim is to deploy an Ethererum node on Azure using version control (GitHub) to manage the development and Infrastructure as Code (Terraform) to deploy and configure the relevant Azure resources. Building an Ethereum node on Azure invoives connecting a compute resource with the node software installed and running on it to the internet and the Ethereum node mesh. Additionally a secure private connection is required for administration. An initial look at [Mastering Ethereum e-book](https://masteringethereum.xyz/) shows that a full node has 2 core components to install, the execution client and the consensus client. There are also 2 sets of network ports to consider, the external Peer-to-Peer (P2P) ports and the internal admin ports. The main onstraints for the project are costs and security.
 
### Costs
The budget for this project is restricted, so at each stage of this project I'll be looking carefully at costs in Azure and finding ways to minimise them. If it's not feasible to do a full node then there are a couple of other node types to consider that might be more feasible. A Sepolia test node is also going to be cheaper than a full node. I'll compare standard VM vs Containerisation.

### Security
I need to make sure that the system is secure. I'm thinking of using a basic VNET with Network Security Group (NSG) network architecture. I want to take a look at the network ports that are required and also to get an idea of the costs for data ingress and egress. 

## Project stages
The following are the basic stages for this project.

### [1) Project plan](ProjectPlan.md)
### [2) Feasibility study and scope](FeasibilityStudy.md)
### [3) High level design](HighLevelDesign.md)
### [4) Low level design](LowLevelDesign.md)
### [5) Implementation](AsBuilt.md)
### [6) Project de-brief ]()






