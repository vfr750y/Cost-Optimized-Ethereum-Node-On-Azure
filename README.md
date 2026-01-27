# Ethereum Node on Azure
## Overview of project
Building an Ethereum node on Azure is essentially a matter of connecting a VM with the node software to the internet.
My early thinking is that this project will follow these steps:

## Project stages
[Core Solidity 1-25](core-solidity.md)
### [Stage 1) Project plan](ProjectPlan.md)
### [Stage 2) Feasibility study](FeasibilityStudy.md)
### [Stage 3) High level design]()
### [Stage 4) Low level design]()
### [Stage 5) Implementation]()
### [Stage 6) Project de-brief ]()

### Next steps
We are on a limited budget so at each stage of this project I'll be looking carefully at costs in Azure and finding ways to minimise them.
Early thoughts. How to secure the system. Azure - hub and spoke architecture. VM vs Containerisation.
As a starting point for the feasibility study I want to take a look at the network ports that are required and also to get an idea of the costs for data ingress and egress. Looks like a full node has 2 components to install the execution client and the consensus client. There are also 2 sets of network ports to consider, the external Peer-to-Peer (P2P) ports and the internal admin ports.






