# Data Flow Diagram

## SFS (SFSTurbo) List Skill Data Flow

```mermaid
graph TD
    A[Agent / User] --> B{Execution Mode}
    B -->|Primary| C[hcloud CLI]
    B -->|Fallback| D[Python SDK]
    C --> E[Huawei Cloud SFS v1 API]
    D --> E
    E --> F[SFSTurbo Service]

    F --> G[File System List Data]

    G --> O[Query Results]
    O --> P[SFS Names / Summary Report]
```

## API Paths

The API path below is read from the `huaweicloudsdksfsturbo` v1 SDK
`_list_shares_http_info` `resource_path` definition.

| Category | API Path | Methods |
|----------|----------|---------|
| SFS file system (list) | `/v1/{project_id}/sfs-turbo/shares/detail` | ListShares |
