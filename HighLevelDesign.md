# High Level Design

## High level solution
### Entity relationship diagram
```mermaid
erDiagram
    USER ||--o{ WALLET (e.g. Metamask): "manages"
    WALLET ||--o| LIGHT_NODE (e.g. Lodestar or Helios) : "sends signed transactions to"
    LIGHT_NODE ||--|{ ETHEREUM_NETWORK (E.g.Sepolia) : "gossips / syncs headers"

```

