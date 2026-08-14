# Data Flow Diagram

## CCE Query Skill Data Flow

```mermaid
graph TD
    A[Agent / User] --> B{Execution Mode}
    B -->|Primary| C[hcloud CLI]
    B -->|Fallback| D[Python SDK]
    C --> E[Huawei Cloud CCE API]
    D --> E
    E --> F[CCE Service]

    F --> G[Cluster List Data]
    F --> H[Cluster Detail Data]
    F --> I[Node Data]

    G --> O[Query Results]
    H --> O
    I --> O

    O --> P[Analysis & Report]
```

## Query Categories

All API paths below are read from the `huaweicloudsdkcce` v3 SDK `_http_info` `resource_path` definitions.

| Category | API Path | Methods |
|----------|----------|---------|
| Clusters | `/api/v3/projects/{project_id}/clusters` | ListClusters |
| Cluster Detail | `/api/v3/projects/{project_id}/clusters/{cluster_id}` | ShowCluster |
| Nodes | `/api/v3/projects/{project_id}/clusters/{cluster_id}/nodes` | ListNodes |
| Node Detail | `/api/v3/projects/{project_id}/clusters/{cluster_id}/nodes/{node_id}` | ShowNode |
