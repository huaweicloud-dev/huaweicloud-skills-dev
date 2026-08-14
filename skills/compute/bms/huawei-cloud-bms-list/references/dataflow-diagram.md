# Data Flow Diagram

## BMS List Skill Data Flow

```mermaid
graph TD
    A[Agent / User] --> B{Execution Mode}
    B -->|Primary| C[hcloud CLI]
    B -->|Fallback| D[Python SDK]
    C --> E[Huawei Cloud BMS v1 API]
    D --> E
    E --> F[BMS Service]

    F --> G[Server List Data]

    G --> O[Query Results]
    O --> P[Server Names / Summary Report]
```

## API Path

The API path below is read from the `huaweicloudsdkbms` v1 SDK
`_list_bare_metal_servers_http_info` `resource_path` definition.

| Category | API Path | Methods |
|----------|----------|---------|
| Bare Metal Servers (list) | `/v1/{project_id}/baremetalservers/detail` | ListBareMetalServers |
