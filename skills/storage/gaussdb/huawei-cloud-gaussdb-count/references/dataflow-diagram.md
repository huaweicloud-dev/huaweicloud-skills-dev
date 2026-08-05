# Data Flow Diagram

```mermaid
flowchart TD
    A[User/Agent] -->|"Count GaussDB instances and size"| B{hcloud CLI available?}
    B -->|Yes| C["hcloud GaussDBforopenGauss ListInstances --cli-region={region} --limit={limit}"]
    B -->|Yes| D["hcloud GaussDB ListGaussMySqlInstances --cli-region={region} --limit={limit}"]
    B -->|No| E["Python SDK: GaussDBforopenGaussClient.list_instances()"]
    B -->|No| F["Python SDK: GaussDBClient.list_gauss_my_sql_instances()"]
    C --> G["GET /v3/{project_id}/instances (openGauss)"]
    D --> H["GET /v3/{project_id}/instances (MySQL)"]
    E --> G
    F --> H
    G --> I[Huawei Cloud GaussDB API]
    H --> I
    I --> J["Response: instances[] + total_count + volume.size per instance"]
    J --> K["Read total_count (authoritative total)"]
    J --> M["Sum instances[].volume.size (GB)"]
    K --> N["Output count"]
    M --> N["Output total storage size"]
    N --> O["Output GaussDB count + size to user"]
```

## API Endpoint

| Item | Value |
|------|-------|
| Method | `GET` |
| Path | `/v3/{project_id}/instances` (both openGauss and MySQL services) |
| SDK method | `list_instances` (huaweicloudsdkgaussdbforopengauss v3), `list_gauss_my_sql_instances` (huaweicloudsdkgaussdb v3) |
| Source | SDK `_list_instances_http_info` / `_list_gauss_my_sql_instances_http_info` resource_path |
