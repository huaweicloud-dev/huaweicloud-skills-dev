# Data Flow Diagram

## Architecture Overview

```mermaid
graph LR
    subgraph Agent
        A[AI Agent]
    end
    subgraph Execution
        A -->|"1. hcloud ECS ListServersDetails (resolve name)"| E[KooCLI ECS]
        A -->|"2. hcloud EIP ListPublicips (primary)"| B[KooCLI EIP]
        A -->|"3. huaweicloudsdkeip (fallback)"| C[Python SDK]
    end
    E -->|"ECS ID"| B
    E -->|"ECS ID"| C
    B --> D["Huawei Cloud EIP API<br/>GET /v1/{project_id}/publicips (ListPublicips)"]
    C --> D
    D --> F[(EIPs)]
    F --> B
    F --> C
    B -->|"EIP list bound to ECS"| A
    C -->|"EIP list bound to ECS"| A
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant A as Agent
    participant E as hcloud CLI (ECS)
    participant C as hcloud CLI (EIP)
    participant S as Python SDK
    participant V as EIP Service

    U->>A: What is the EIP of ECS <id/name>?
    A->>A: Check prerequisites (hcloud, credentials)
    alt ECS name given
        A->>E: hcloud ECS ListServersDetails --name=<name>
        E-->>A: ECS ID
    end
    A->>C: hcloud EIP ListPublicips/v3 --vnic.device_id.1=<ecs-id>
    C->>V: GET /v1/{project_id}/publicips?vnic.device_id=<ecs-id>
    V-->>C: EIPs bound to the ECS
    C-->>A: EIPs + count
    alt CLI unavailable
        A->>S: list_publicips(ListPublicipsRequest(vnic_device_id))
        S->>V: GET /v1/{project_id}/publicips
        V-->>S: EIPs bound to the ECS
        S-->>A: EIPs + count
    end
    A-->>U: EIP public IP, EIP ID, status, bandwidth, binding details
```

## Deployment Architecture

```mermaid
graph TB
    subgraph Huawei Cloud
        subgraph VPC
            ECS[ECS instance]
            EIP[Elastic IP]
            ECS -.bound to.-> EIP
        end
    end
    subgraph User Side
        HC[hcloud CLI] -->|AK/SK auth| VPC
        SDK[huaweicloudsdkeip] -->|AK/SK auth| VPC
    end
```

## Security Notes

- Only read-only operations are invoked: `GET /v1/{project_id}/publicips` (list),
  `GET /v1/{project_id}/publicips/{publicip_id}` (show), `GET /v1/{project_id}/cloudservers/detail` (list servers)
  and `GET /v1/{project_id}/cloudservers/{server_id}` (show server)
- Credentials are never hardcoded in the skill; they come from the user's KooCLI configuration or environment variables
- Least-privilege policies (`vpc:publicIps:list`/`get`, `ecs:servers:list`/`get`) are documented in `references/eip-policies.md`
