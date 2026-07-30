# Data Flow Diagram

```mermaid
graph TD
    A[User Request] --> B[Skill: huawei-cloud-ecs-query]
    B --> C{Environment Check}
    C -->|Pass| D{Identify Query Type}
    C -->|Fail| E[Fix Environment]
    E --> C

    D -->|Instance List| F[list_servers_details.py]
    D -->|Instance Detail| G[show_server.py]
    D -->|Flavor List| H[list_flavors.py]
    D -->|Keypair List| I[nova_list_keypairs.py]
    D -->|Server Groups| J[list_server_groups.py]
    D -->|Block Devices| K[list_server_block_devices.py]
    D -->|Network Interfaces| L[list_server_interfaces.py]
    D -->|Tags| M[list_server_tags.py / show_server_tags.py]
    D -->|Quotas| N[show_server_limits.py]
    D -->|Other| O[Other Query Scripts]

    F --> P[huaweicloudsdkecs SDK]
    G --> P
    H --> P
    I --> P
    J --> P
    K --> P
    L --> P
    M --> P
    N --> P
    O --> P

    P --> Q[Huawei Cloud ECS API]
    Q --> R[JSON Response]
    R --> S[Structured Output to User]
```

## Data Flow Description

1. **User Request** — User provides query intent (e.g., "list all ECS instances")
2. **Skill** — huawei-cloud-ecs-query skill is invoked
3. **Environment Check** — Verify Python, SDK, credentials, and service availability
4. **Identify Query Type** — Match user intent to the appropriate script
5. **Execute Script** — Run the Python query script via `skill action=exec`
6. **SDK Call** — Script calls Huawei Cloud Python SDK (`huaweicloudsdkecs`)
7. **API Request** — SDK sends REST API request to Huawei Cloud ECS service
8. **JSON Response** — API returns JSON response
9. **Structured Output** — Script parses and formats results for user consumption
