Date 27-Jan-2026

## Why build a test Ethereum node?
This project aims to provide benefits by doing the following:

- Providing a GitHub repository containing project plan, implementation steps and research findings.
- Testing and documenting a method for installation
- Research and minimise costs
- Providing everyone with a free learning opportunity

There are several different types of Ethereum node:


## Full node.
A full node's core software is in two parts, an execution client and a consensus client. They can be thought of as a team and the node can only properly function when both clients are working correctly. There are two versions of the full node, default and archive. The difference between them is the amount of chain data accessible. Archive nodes contain the entire chain from the genesis block (around 15 to 18 TB). The default behaviour for a full node is to prune the data to save space. A default node is around 1.5 to 2 TB.

### How does a full node communicate?
The node discovers other nodes, then it connects with them via a handshake, then gossips with other nodes. A node will typically communicate with between 50 and 100 peers using default settings.
For normal operations (there are a few edge cases) nodes communicate with other nodes on the peer-to-peer network (P2P).

## Validator node
A third component called a validator can be added to the full node. The validator is used as the signing agent for new blocks. If all three components, execution client, consensus client and validator client are installed together, new blocks on the Ethereum chain can be added with that node. A validating node also needs a minimum stake of 32 ETH to allow it to be an active participant in the "Proof of Stake" system. For the purposes of this proof of concept, due to the staking cost, a validator is out of scope.

## Light node
Light clients are a way that low-power devices, like cell phones, can do self validation of transactions and dApp state. Unlike full nodes, light clients do not download and store the entire blockchain. Instead, they download only the headers of each block and employ Merkle proofs to verify transactions. A light node allows users to verify state directly without having to use a third party like Infura.

## What are the minimum Azure components required for a full (non-validating) node on Ethereum mainnet?

### Recommended requirements
Operating system - Linux - Ubuntu server
Memory optimized - 8GB RAM per CPU 
CPU - 8 vCPUs (4 physical cores)
Memory - 32 GB RAM - Note: More RAM results in less disk IOPS allowing the node to perform fast enough to keep synchronised.
For storage and internet egress estimates, see specific cost analysis for each client type below:


## Basic cost analysis

### Full node on Ethereum mainnet (default)
Storage - Minimum 2TB - Recommended 4TB - 
Note the default full node is deployed in pruned mode (not archive mode). The chain size for a Geth client is currently ~1.5TB 
(A Geth client is a particular deployment of the ETH node written in Go)
Data egress is estimated at between 1 and 3 TB per month.
Using the Azure pricing calculator to give a basic estimate of costs for a full node (not archive):

| Item name    | Item value      | Cost (USD p/m) |Description                             |
|:-------------|:----------------|:---------------|:---------------------------------------|
| VM           | D8sv5           | 129            | 8vCPUs 32GB RAM (3yr commitment)       |
| Managed Disk | 2TB SSD(Premium)| 259            | 7500 IOPS 250MB/Sec                    |
| Data egress  | 2TB             | 114            | Internet based and routed over internet|
| **Total**    |                 | **502**        |                                        |

### Sepolia testnet full node (default)?
As the Sepolia test net is not used for production scale transactions and only contains a chain created in October 2021 the storage required is significantly reduced. As storage is the main cost for an Azure node, reducing the disk size required should make a node cheaper to run. In this case, we won't be able to interact with the Ethereum mainnet but it will still provide a proof of concept.

Storage - Minimum 1TB - Recommended 2TB (The current chain size for Sepolia is around 650GB depending on the client version).
Data egress - Around 1 to 1.5 TB per month based on 50 to 100 peers.

| Item name    | Item value      | Cost (USD p/m) |Description                             |
|:-------------|:----------------|:---------------|:---------------------------------------|
| VM           | D8sv5           | 129            | 8vCPUs 32GB RAM  (3yr commitment)      |
| Managed Disk | 1TB SSD(Premium)| 135            | 7500 IOPS 250MB/Sec                    |
| Data egress  | 1.25TB          | 69             | Internet based and routed over internet|
| **Total**    |                 | **333**        |                                        |


### Light node (e.g. Lodestar) node cost comparison.


Storage - Minimum 2GB - With a light node, only the headers are synchronised.
Memory - Max 1GB
Data egress - <10GB per month

| Item name    | Item value      | Cost (USD p/m) |Description                             |
|:-------------|:----------------|:---------------|:---------------------------------------|
| VM           | B2pts v2        | 8              | 2vCPUs 1GB RAM                         |
| Managed Disk | 4GB SSD(Premium)| 1              | 7500 IOPS 250MB/Sec                    |
| Data egress  | 10GB            | 0              | First 100GB is free                    |
| **Total**    |                 | **9**          |                                        |


### Light node on Azure Container instance

An Azure container instance is charged by the second

ACI Limit: Azure Container Instances generally provide a maximum of 50 GB of local non-persistent storage. This is barely enough to hold the operating system and the Lodestar binary, let alone a blockchain database.

**Latency**
The Network Latency Trap: To get more storage in ACI, you must mount an Azure File Share. Because this is network-attached storage (NAS) running over SMB/NFS protocols, it introduces micro-latencies. Ethereum execution clients (like Geth or Reth) require sub-millisecond disk latency to stay synced with the "tip" of the chain. Using Azure Files for a full node results in your node constantly falling behind.

**Storage**
A full node doesn't just "store" data; it constantly reads and writes to a database to verify transactions.

**IOPS**
Full Node: Requires 10,000 to 100,000+ IOPS. A standard Azure File Share or even a standard Managed Disk mounted to a container will often throttle these requests, causing the database to become "stuck."

Light Node: Only tracks block headers and sync committee signatures. It requires virtually zero IOPS once the initial 20-second sync is complete. It fits perfectly within ACI’s 50GB local disk limit.

So we can't realistically use ACI for a full node, but for a lightnode it seems a good choice.

Here is the cost breakdown for an Azure container instance:

| Item name    | Item value      | Cost (USD p/m) |Description                                             |
|:-------------|:----------------|:---------------|:-------------------------------------------------------|
| CPU          | 1vCPU           | 1              | est 24 hours per month                                 |
| Memory       | 1GB             | 0.1            | est 24 hours per month                                 |
| Managed Disk | 50GB Temp disk  | 0              | Sequential read/write ~4000, Randowm Read/Write ~ 750  |
| Data egress  | 10GB            | 0              | First 100GB is free  per subscription                  |
| **Total**    |                 | **1.1**        |                                                        |

### Summary of cost analysis

| Node Type | Best Use Case | Monthly Cost (USD) | Key Hardware Driver |
| :--- | :--- | :--- | :--- |
| Mainnet Full Node | Production apps & DeFi | $502.00 | 2TB+ SSD & High Egress |
| Sepolia Testnet | Dev & Proof of Concept | $333.00 | 1TB Storage |
| Light Node (VM) | Basic header queries | $9.00 | Minimal 4GB Storage |
| Light Node (ACI) | Low-cost experimentation | $1.10 | Serverless / No persistent disk |

Kubernetes
Other cloud providers



## What other components are required for the deployment and configuration of the node?
GitHub account
GitHub to Terraform integration
Terraform account
Terraform to Azure integration

**Port configuration** 

### Public P2P Ports
These ports must be open to the internet (TCP/UDP) to allow your node to find peers and stay synchronized.

| Port  | Protocol  | Component         | Description                          |
|:------|:----------|:------------------|:-------------------------------------|
| 30303 | TCP & UDP | Execution Client  | Transaction gossip and block syncing |
| 9000  | TCP & UDP | Consensus Client  | Beacon chain gossip and attestations |

### Local Service Ports (Private)
These should **not** be exposed to the internet. They are used for local communication between clients or by your own dApps/wallets.

| Port  | Protocol  | Component         | Description                          |
|:------|:----------|:------------------|:-------------------------------------|
| 8545  | TCP       | Execution Client  | JSON-RPC API (HTTP)                  |
| 8546  | TCP       | Execution Client  | WebSockets API                       |
| 8551  | TCP       | Engine API        | Authenticated EL-CL link (JWT)       |
| 5052  | TCP       | Consensus Client  | Beacon Node REST API                 |





