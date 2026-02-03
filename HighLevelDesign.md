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