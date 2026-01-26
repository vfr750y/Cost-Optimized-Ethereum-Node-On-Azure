# Sepolia-Full-Node-On-Azure
## Overview of project
To set up a Sepolia test net node on Azure is essentially connecting a VM to the internet.
My early thinking is that this project will follow these steps:

## Project plan
### Step 1) Feasibility study
    - Why am I doing this?
    - What is a full node? 
    - How does it communicate? 
    - What are the minimum Azure components required to get a node?
    - How much do these cost?
    - Have we looked at all angles are there any other alternative architectures? - I.e. state healing / up-time.

### Step 2) High level design
    - High level description of proposed solution
    - Logical Architecture diagram + Explanation
    - Description of each component
    - Description of logical data flow
    - High level risk benefit
    - Cost estimate
    - Outline of set up steps
    - Outline of acceptance testing procedure

### Step 3) Low level design
    - Detailed description of component configuration
    - Sequence diagrams for protocol interactions
    - Detailed breakdown of costs
    - Detailed description of security risks and mitigations
    - Detailed implementation steps
    - Detailed testing procedure

### Step 4) Implementation
    - As built documentation
    - Acceptance test results

### Step 5) Project de-brief
    - Learning outcomes
    - Recommendations

### Next steps
We are on a limited budget so at each stage of this project I'll be looking carefully at costs in Azure and finding ways to minimise them.
Early thoughts. How to secure the system. Azure - hub and spoke architecture. VM vs Containerisation.
As a starting point for the feasibility study I want to take a look at the network ports that are required and also to get an idea of the costs for data ingress and egress. Looks like a full node has 2 components to install the execution client and the consensus client. There are also 2 sets of network ports to consider, the external Peer-to-Peer (P2P) ports and the internal admin ports.






