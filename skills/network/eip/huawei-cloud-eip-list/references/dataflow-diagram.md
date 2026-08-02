# Data Flow Diagram

## Architecture Overview

```mermaid
graph LR
    subgraph Agent
        A[AI Agent]
    end
    subgraph Execution
        A -->|"1. hcloud EIP ListPublicips (primary)"| B[KooCLI EIP]
        A -->|"2. huaweicloudsdkeip (fallback)"| C[Python SDK]
    end
    B --> D["Huawei Cloud EIP API<br/>GET /v1/{project_id}/publicips (ListPublicips)"]
    C --> D
    D --> E[(EIPs)]
    E --> B
    E --> C
    B -->|"EIP list + count"| A
    C -->|"EIP list + count"| A
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant A as Agent
    participant C as hcloud CLI (EIP)
    participant S as Python SDK
    participant V as EIP Service

    U->>A: List my EIPs
    A->>A: Check prerequisites (hcloud, credentials)
    A->>C: hcloud EIP ListPublicips --cli-region=cn-north-4
    C->>V: GET /v1/{project_id}/publicips
    V-->>C: EIP list + count
    C-->>A: EIPs + count
    alt CLI unavailable
        A->>S: list_publicips(ListPublicipsRequest)
        S->>V: GET /v1/{project_id}/publicips
        V-->>S: EIP list
        S-->>A: EIPs + count
    end
    A-->>U: Formatted EIP inventory + count
```

## Deployment Architecture

```mermaid
graph TB
    subgraph Huawei Cloud
        subgraph VPC
            EIP[Elastic IPs]
        end
    end
    subgraph User Side
        HC[hcloud CLI] -->|AK/SK auth| VPC
        SDK[huaweicloudsdkeip] -->|AK/SK auth| VPC
    end
```

## Security Notes

- Only read-only operations `GET /v1/{project_id}/publicips` (list) and `GET /v1/{project_id}/publicips/{publicip_id}` (show) are invoked
- Credentials are never hardcoded in the skill; they come from the user's KooCLI configuration or environment variables
- Least-privilege EIP policy `vpc:publicIps:list` / `vpc:publicIps:get` is documented in `references/eip-policies.md`
