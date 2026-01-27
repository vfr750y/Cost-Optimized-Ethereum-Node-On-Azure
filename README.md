# Ethereum Node on Azure
## Overview of project
Building an Ethereum node on Azure is essentially a matter of connecting a VM with the node software to the internet.
My early thinking is that this project will follow these steps:

## Project plan
### Step 1) Feasibility study
### Step 2) High level design
### Step 3) Low level design
### Step 4) Implementation
### Step 5) Project de-brief

### Next steps
We are on a limited budget so at each stage of this project I'll be looking carefully at costs in Azure and finding ways to minimise them.
Early thoughts. How to secure the system. Azure - hub and spoke architecture. VM vs Containerisation.
As a starting point for the feasibility study I want to take a look at the network ports that are required and also to get an idea of the costs for data ingress and egress. Looks like a full node has 2 components to install the execution client and the consensus client. There are also 2 sets of network ports to consider, the external Peer-to-Peer (P2P) ports and the internal admin ports.






