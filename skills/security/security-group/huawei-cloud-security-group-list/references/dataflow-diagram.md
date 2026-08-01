# Data Flow Diagram

## Architecture Overview

```mermaid
graph LR
    subgraph Agent
        A[AI Agent]
    end
    subgraph Execution
        A -->|"1. hcloud VPC ListSecurityGroups (primary)"| B[KooCLI VPC]
        A -->|"2. huaweicloudsdkvpc (fallback)"| C[Python SDK]
    end
    B --> D["Huawei Cloud VPC API<br/>GET /v3/{project_id}/vpc/security-groups (ListSecurityGroups)"]
    C --> D
    D --> E[(Security Groups)]
    E --> B
    E --> C
    B -->|"Security group list + count"| A
    C -->|"Security group list + count"| A
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant A as Agent
    participant C as hcloud CLI (VPC)
    participant S as Python SDK
    participant V as VPC Service

    U->>A: List my security groups
    A->>A: Check prerequisites (hcloud, credentials)
    A->>C: hcloud VPC ListSecurityGroups --cli-region=cn-north-4
    C->>V: GET /v3/{project_id}/vpc/security-groups
    V-->>C: Security group list + count
    C-->>A: Security groups + count
    alt CLI unavailable
        A->>S: list_security_groups(ListSecurityGroupsRequest)
        S->>V: GET /v3/{project_id}/vpc/security-groups
        V-->>S: Security group list
        S-->>A: Security groups + count
    end
    A-->>U: Formatted security group inventory + count
```

## Deployment Architecture

```mermaid
graph TB
    subgraph Huawei Cloud
        subgraph VPC
            SG[Security Groups]
        end
    end
    subgraph User Side
        HC[hcloud CLI] -->|AK/SK auth| VPC
        SDK[huaweicloudsdkvpc] -->|AK/SK auth| VPC
    end
```

## Security Notes

- Only read-only operation `GET /v3/{project_id}/vpc/security-groups` is invoked
- Credentials are never hardcoded in the skill; they come from the user's KooCLI configuration or environment variables
- Least-privilege VPC policy `vpc:securityGroups:list` is documented in `references/vpc-policies.md`
