# Data Flow Diagram

## EVS List Skill Data Flow

```mermaid
graph TD
    A[Agent / User] --> B{Execution Mode}
    B -->|Primary| C[hcloud CLI]
    B -->|Fallback| D[Python SDK]
    C --> E[Huawei Cloud EVS v2 API]
    D --> E
    E --> F[EVS Service]

    F --> G[Disk List Data]

    G --> O[Query Results]
    O --> P[Disk Names / Summary Report]
```

## API Path

The API path below is read from the `huaweicloudsdkevs` v2 SDK
`_list_volumes_http_info` `resource_path` definition.

| Category | API Path | Methods |
|----------|----------|---------|
| Elastic Volume Service (list) | `/v2/{project_id}/cloudvolumes/detail` | ListVolumes |
