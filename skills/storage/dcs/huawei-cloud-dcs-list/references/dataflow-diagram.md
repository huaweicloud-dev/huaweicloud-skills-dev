# Data Flow Diagram

## DCS List Skill Data Flow

```mermaid
graph TD
    A[Agent / User] --> B{Execution Mode}
    B -->|Primary| C[hcloud CLI]
    B -->|Fallback| D[Python SDK]
    C --> E[Huawei Cloud DCS API]
    D --> E
    E --> F[DCS Service]

    F --> G[Instance List Data]
    F --> H[Instance Detail Data]

    G --> O[Query Results]
    H --> O

    O --> P[Analysis & Report]
```

## Query Categories

All API paths below are read from the `huaweicloudsdkdcs` v2 SDK `_http_info` `resource_path` definitions.

| Category | API Path | Methods |
|----------|----------|---------|
| Instance List | `/v2/{project_id}/instances` | ListInstances |
| Instance Detail | `/v2/{project_id}/instances/{instance_id}` | ShowInstance |
