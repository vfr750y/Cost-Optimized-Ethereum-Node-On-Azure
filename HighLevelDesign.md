# High Level Design

## High level solution
### Entity relationship diagram
```mermaid
erDiagram
    USER ||--o{ WALLET : "manages"
    WALLET ||--o| LIGHT_NODE : "sends signed transactions to"
    LIGHT_NODE ||--|{ ETHEREUM_NETWORK : "gossips / syncs headers"

    subgraph Azure_Cloud_Environment
        USER {
            string azure_tenant_id
            string identity_ref
        }
        WALLET {
            string public_address
            string vault_secret_uri
            string network_type
        }
        LIGHT_NODE {
            string client_flavor "Lodestar/Helios"
            string rpc_endpoint
            int p2p_port
            string instance_id "Container/VM"
        }
    end

    subgraph Blockchain_P2P_Layer
        ETHEREUM_NETWORK {
            string chain_id
            string protocol_version
            int peer_count
        }
    end
```

```mermaid
graph TB
    subgraph Azure_Subscription [Azure Cloud Environment]
        direction TB
        
        USER["<b>User</b><hr/>- Azure_Tenant_ID<br/>- Entra_ID_Ref"]
        
        WALLET["<b>Wallet</b><hr/>- Public_Address<br/>- KeyVault_Secret_URI<br/>- Network_ID"]
        
        LIGHT_NODE["<b>Light Node (Lodestar/Helios)</b><hr/>- Client_Flavor<br/>- RPC_Endpoint<br/>- P2P_Port<br/>- Azure_Resource_ID"]

        USER -- "owns" --> WALLET
        WALLET -- "transacts with" --> LIGHT_NODE
    end

    subgraph P2P_Network [Public Ethereum Network]
        ETH_NET["<b>Ethereum Node Network</b><hr/>- Chain_ID<br/>- Protocol_Version<br/>- Peer_Count"]
    end

    LIGHT_NODE -- "gossips with" --> ETH_NET

    %% Styling
    style Azure_Subscription fill:#f9faff,stroke:#0078d4,stroke-width:2px
    style P2P_Network fill:#fff9f0,stroke:#e67e22,stroke-width:2px
    style USER fill:#fff,stroke:#333
    style WALLET fill:#fff,stroke:#333
    style LIGHT_NODE fill:#fff,stroke:#333
    style ETH_NET fill:#fff,stroke:#333
```
