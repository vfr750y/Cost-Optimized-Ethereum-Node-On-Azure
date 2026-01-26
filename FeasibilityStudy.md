## Why build a test Ethereum node?
This project aims to provide benefits by doing the following:

- Providing a GitHub repository containing project plan, implementation steps and research findings.
- Testing and documenting a method for installation
- Research and minimise costs
- Learning opportunity

## What is a full node?
A full node's core software is in two parts, an execution client and a consensus client. They can be thought of as a team and the node can only properly function when both clients are working correctly.

## How does it communicate?
The node discovers other nodes, then it connects with them via a handshake, then gossips with other nodes.
For normal operations (there are a few edge cases) nodes communicate with other nodes on the peer-to-peer network (P2P).

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


### What is a validating node?
A third component called a validator can be added to the full node. The validator is used as the signing agent for new blocks. If all three components, execution client, consensus client and validator client are installed together, new blocks on the Ethereum chain can be added with that node. A validating node also needs a minimum stake of 32 ETH to allow it to be an active participant in the "Proof of Stake" system.



