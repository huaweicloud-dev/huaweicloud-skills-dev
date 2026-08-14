# Data Flow Diagram

## CCE Cluster List Skill Data Flow

```mermaid
graph TD
    A[Agent / User] --> B{Execution Mode}
    B -->|Primary| C[hcloud CLI]
    B -->|Fallback| D[Python SDK]
    C --> E[Huawei Cloud CCE v3 API]
    D --> E
    E --> F[CCE Service]

    F --> G[Cluster List Data]

    G --> O[Query Results]
    O --> P[Cluster Names / Summary Report]
```

## API Path

The API path below is read from the `huaweicloudsdkcce` v3 SDK
`_list_clusters_http_info` `resource_path` definition.

| Category | API Path | Methods |
|----------|----------|---------|
| Clusters (list) | `/api/v3/projects/{project_id}/clusters` | ListClusters |
