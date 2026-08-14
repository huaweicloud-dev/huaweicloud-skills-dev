# Data Flow Diagram

## VPCEP List Skill Data Flow

```mermaid
graph TD
    A[Agent / User] --> B{Execution Mode}
    B -->|Primary| C[hcloud CLI]
    B -->|Fallback| D[Python SDK]
    C --> E[Huawei Cloud VPCEP v1 API]
    D --> E
    E --> F[VPCEP Service]

    F --> G[Endpoint / Service List Data]

    G --> O[Query Results]
    O --> P[VPCEP Names / Summary Report]
```

## API Paths

The API paths below are read from the `huaweicloudsdkvpcep` v1 SDK
`_list_endpoints_http_info` / `_list_endpoint_service_http_info`
`resource_path` definitions.

| Category | API Path | Methods |
|----------|----------|---------|
| VPC Endpoint (list) | `/v1/{project_id}/vpc-endpoints` | ListEndpoints |
| VPC Endpoint Service (list) | `/v1/{project_id}/vpc-endpoint-services` | ListEndpointService |
