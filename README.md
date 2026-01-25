# Sepolia-Full-Node-On-Azure
Notes -
To set up a Sepolia test net node on Azure is essentially connecting a VM to the internet.
My early thinking is that this project will follow these steps:

Step 1) Feasibility study
    - Why am I doing this?
    - What is a full node? 
    - How does it communicate? 
    - What are the minimum Azure components required to get a node?
    - How much do these cost?
    - Have we looked at all angles are there any other alternative architectures?
    - 

Step 2) High level design
    - High level description of proposed solution
    - Logical Architecture diagram + Explanation
    - Description of each component
    - Description of data flow
    - High level risk benefit
    - Cost estimate
    - Outline of set up steps

Step 3) Low level design
    - Detailed description of component configuration
    - Sequence diagrams for protocol interactions
    - Detailed breakdown of costs
    - Detailed description of security risks and mitigations
    - Details implementation steps

We are on a limited budget so at each stage of this project I'll be looking carefully at costs in Azure and finding ways to minimise them.
As a starting point I want to take a look at the network ports that are required and also to get an idea of the costs for data ingress and egress.

