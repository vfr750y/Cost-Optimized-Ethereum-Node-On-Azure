# Ethereum Node on Azure
## Overview of project

This project is going to be a proof of concept. The aim is to deploy an Ethererum node on Azure using terraform to deploy and configure the relevant Azure resources. My early thinking is that building an Ethereum node on Azure is essentially a matter of connecting a VM with the node software to the internet.

I'm expecting this project to happen in these stages:

## Project stages

### [Stage 1) Project plan](ProjectPlan.md)
### [Stage 2) Feasibility study](FeasibilityStudy.md)
### [Stage 3) High level design]()
### [Stage 4) Low level design]()
### [Stage 5) Implementation]()
### [Stage 6) Project de-brief ]()

### Early project considerations. 
The budget for this project is restricted, so at each stage of this project I'll be looking carefully at costs in Azure and finding ways to minimise them. If it's not feasible to do a full node then there are a couple of other node types to consider that might be more feasible. A Sepolia test node is also going to be cheaper than a full node.

I need to make sure that the system is secure. I'm thinking of using a basic hub and spoke network architecture. I want to take a look at the network ports that are required and also to get an idea of the costs for data ingress and egress. 

I'll compare standard VM vs Containerisation or Kubernetes.

I've had a read through the [Mastering Ethereum e-book](https://masteringethereum.xyz/) and it looks like a full node has 2 core components to install, the execution client and the consensus client. There are also 2 sets of network ports to consider, the external Peer-to-Peer (P2P) ports and the internal admin ports.






