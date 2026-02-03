# High Level Design

## High level solution
### Entity relationship diagram
```mermaid
erDiagram
    USER ||--o{ WALLET : "manages"
    WALLET ||--o| LIGHT_NODE : "sends signed transactions to"
    LIGHT_NODE ||--|{ ETHEREUM_NETWORK : "gossips / syncs headers"

```

