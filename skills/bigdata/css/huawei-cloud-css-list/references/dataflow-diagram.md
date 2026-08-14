# Data Flow Diagram

## CSS Cluster List Skill Data Flow

```mermaid
graph TD
    A[Agent / User] --> B{Execution Mode}
    B -->|Primary| C[hcloud CLI]
    B -->|Fallback| D[Python SDK]
    C --> E[Huawei Cloud CSS API]
    D --> E
    E --> F[CSS Service]

    F --> G[Cluster List Data]
    F --> H[Cluster Detail Attributes]

    G --> O[Query Results]
    H --> O

    O --> P[Analysis & Report]
```

## Query Categories

All API paths below are read from the `huaweicloudsdkcss` v1 SDK `_http_info` `resource_path` definitions.

| Category | API Path | Methods |
|----------|----------|---------|
| Cluster List | `/v1.0/{project_id}/clusters` | ListClustersDetails |
