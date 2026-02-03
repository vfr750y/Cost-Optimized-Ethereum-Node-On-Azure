# High Level Design

## High level solution
### Entity relationship diagram
```mermaid
graph TD
    subgraph Azure_Cloud_Environment [Azure Cloud Environment]
        User[User] -- "Manages" --> Wallet[Wallet]
        Wallet -- "Sends RPC Calls" --> LightNode[Light Node: Lodestar/Helios]
    end

    subgraph Blockchain_P2P_Layer [Blockchain P2P Layer]
        LightNode -- "Gossips / Syncs" --> EthNetwork[Ethereum Node Network]
    end

    %% Defining Styles
    style Azure_Cloud_Environment fill:#f0f7ff,stroke:#0078d4,stroke-width:2px
    style Blockchain_P2P_Layer fill:#f5f5f5,stroke:#3c3c3d,stroke-width:2px

```

