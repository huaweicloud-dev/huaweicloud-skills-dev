# Data Flow Diagram

## SWR Repository List Skill Data Flow

```mermaid
graph TD
    A[Agent / User] --> B{Execution Mode}
    B -->|Primary| C[hcloud CLI]
    B -->|Fallback| D[Python SDK]
    C --> E[Huawei Cloud SWR API]
    D --> E
    E --> F[SWR Service]

    F --> G[Repository List Data]
    F --> H[Repository Detail Attributes]

    G --> O[Query Results]
    H --> O

    O --> P[Analysis & Report]
```

## Query Categories

All API paths below are read from the `huaweicloudsdkswr` v2 SDK `_http_info` `resource_path` definitions.

| Category | API Path | Methods |
|----------|----------|---------|
| Repository List | `/v2/manage/projects/{project_id}/repos` | ListReposDetails |
