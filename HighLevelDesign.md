# High Level Design

## High level solution
### Entity relationship diagram
```mermaid
erDiagram
    USER ||--o{ WALLET : "manages"
    WALLET ||--o{ TRANSACTION : "signs"
    TRANSACTION }o--|| LIGHT_CLIENT : "submitted_to"
    LIGHT_CLIENT ||--o{ P2P_NETWORK : "broadcasts_to / syncs_with"

    USER {
        string user_id PK
        string auth_method
    }

    WALLET {
        string public_address PK
        string derivation_path
        string key_type "ECDSA"
    }

    TRANSACTION {
        string tx_hash PK
        int nonce
        uint256 value
        uint256 gas_limit
        string signature
    }

    LIGHT_CLIENT {
        string client_id PK
        string flavor "Lodestar/Helios"
        string sync_status
        hash trusted_checkpoint
    }

    P2P_NETWORK {
        int chain_id PK
        string network_name "Mainnet/Sepolia"
        int active_peers
    }

```

