## Overview of project

This project includes the following steps.

## Project plan
### Step 1) Requirements anaylsis
    - Requirements analysis
    - Assumptions
    - Analysis of Ethereum node types 
    - Analysis of Azure resources
    - Cost analysis
    - Definition of scope
    - Risks
    - Investigation into alternative solutions

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






