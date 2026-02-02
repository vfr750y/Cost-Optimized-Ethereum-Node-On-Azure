Date 27-Jan-2026

## Why build a test Ethereum node?
This project aims to provide benefits by doing the following:

- Providing a GitHub repository containing project plan, implementation steps and research findings.
- Testing and documenting a method for installation
- Research and minimise costs
- Providing everyone with a free learning opportunity

There are several different types of Ethereum node:

## Assumptions and project constraints

- Minimising costs is highest priority.
- We are not concerned with the capability of the deployed node, only that it is able to communicate with Ethereum blockchain (testnet or mainnet).
- Azure will be used as the platform for deployment.
- A deployment method using Infrastructure as Code is preferred.


## Full node.
A full node's core software is in two parts, an execution client and a consensus client. They can be thought of as a team and the node can only properly function when both clients are working correctly. There are two versions of the full node, default and archive. The difference between them is the amount of chain data accessible. Archive nodes contain the entire chain from the genesis block (around 15 to 18 TB). The default behaviour for a full node is to prune the data to save space. A default node is around 1.5 to 2 TB.

### How does a full node communicate?
The node discovers other nodes, then it connects with them via a handshake, then gossips with other nodes. A node will typically communicate with between 50 and 100 peers using default settings.
For normal operations (there are a few edge cases) nodes communicate with other nodes on the peer-to-peer network (P2P).

## Validator node
A third component called a validator can be added to the full node. The validator is used as the signing agent for new blocks. If all three components, execution client, consensus client and validator client are installed together, new blocks on the Ethereum chain can be added with that node. A validating node also needs a minimum stake of 32 ETH to allow it to be an active participant in the "Proof of Stake" system. For the purposes of this proof of concept, due to the staking cost, a validator is out of scope.

## Light node
Light clients are a way that low-power devices, like cell phones, can do self validation of transactions and dApp state. Unlike full nodes, light clients do not download and store the entire blockchain. Instead, they download only the headers of each block and employ Merkle proofs to verify transactions. A light node allows users to verify state directly without having to use a third party like Infura.

## Stateless light node
Stateless clients verify blockchain data without storing local state or synchronizing with the network. Stateless clients operate entirely on demand using compact cryptographic proofs: Merkle proofs for execution-layer data inclusion, and consensus proofs — such as sync committee attestations or aggregated zk-proofs — to validate that the block originates from the correct validator set and belongs to the canonical chain.

## Basic cost analysis as of 29-Jan-2026

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


### Light node and Stateless light node on Azure Container instance

An Azure container instance is charged by the second

A light node requires virtually zero IOPS once the initial 20-second sync is complete. It fits perfectly within ACI’s 50GB local disk limit.

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

| Node Type | Monthly Cost (USD) | Key Hardware Driver |
| :--- | :--- | :--- |
| Mainnet Full Node | $502.00 | 2TB+ SSD & High Egress |
| Sepolia Testnet | $333.00 | 1TB Storage |
| Light Node (VM) | $9.00 | Minimal 4GB Storage |
| Light Node (ACI) / Stateless light node | $1.10 | Serverless / No persistent disk |




## What other components are required for the deployment and configuration of the node?
GitHub account
Terraform account
GitHub to Terraform integration
Terraform to Azure integration

## Risks
### State Access
Every time you want to interact with a contract (e.g., checking a Uniswap price or your wallet balance), the light node must perform a Merkle Proof request to a peer. Instead of a local disk read (micro-seconds), you’re doing a network round-trip (milliseconds).

Full nodes treat light client support as a luxury service. When a node's hardware is under pressure, it will "shed" light clients first to prioritize its own survival. The three main triggers for this are:

- State Spikes: High market activity (like NFT mints) forces the node to prioritize local Disk/CPU tasks over answering external queries.

- Bandwidth Limits: Providing "proofs" to light clients consumes significant data; operators often kill these connections to stay under bandwidth caps.

- Upgrade Stress: As the network grows (e.g., the 2026 "Glamsterdam" upgrade), the increased data per block forces nodes to drop "extra" tasks like serving light clients just to stay synced.

We might be able to mitigate the latency issue by deploying the node to a more central location such as east US or somewhere in Europe.

### Uptime vs node reputation
Keeping a node running creates "Peer Stickiness." If you keep turning it off and only use it when needed, it may result in poor response times from full node peers. 

**Peer Discovery Lag**: If you only turn your node on when you need it, it must spend the first 30–60 seconds "finding its friends." It has to query bootnodes, find peers that support light client requests, and perform handshakes. 

**sampling activity**
A light node gossips with its peers every 12 seconds, sampling parts of the blockchain as they appear. If they can successfully pull 32 random pieces of a block's data, there is a 99.999% mathematical certainty that the entire block is available. Ethereum nodes keep a "scoring" system for their peers. If your light node is constantly disappearing (going offline), full nodes will rank you as a "low-quality peer" and may deprioritize your requests during busy periods. High uptime helps you maintain connections to high-quality, high-speed full nodes.


