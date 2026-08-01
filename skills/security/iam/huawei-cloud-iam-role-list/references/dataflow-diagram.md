# Data Flow Diagram

## Architecture Overview

```mermaid
graph LR
    subgraph Agent
        A[AI Agent]
    end
    subgraph Execution
        A -->|"1. hcloud IAM KeystoneListPermissions (primary)"| B[KooCLI IAM]
        A -->|"2. ListPoliciesV5 / huaweicloudsdkiam (fallback)"| C[Python SDK]
    end
    B --> D["Huawei Cloud IAM API<br/>GET /v3/roles/permissions (KeystoneListPermissions)"]
    C --> D
    D --> E[(IAM Roles)]
    E --> B
    E --> C
    B -->|"Role list + count"| A
    C -->|"Role list + count"| A
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant A as Agent
    participant C as hcloud CLI (IAM)
    participant S as Python SDK
    participant I as IAM Service

    U->>A: List my IAM roles
    A->>A: Check prerequisites (hcloud, credentials)
    A->>C: hcloud IAM KeystoneListPermissions --cli-region=cn-north-4
    C->>I: GET /v3/roles/permissions
    I-->>C: Role list + count
    C-->>A: Roles + count
    alt CLI unavailable
        A->>S: keystone_list_permissions(KeystoneListPermissionsRequest)
        S->>I: GET /v3/roles/permissions
        I-->>S: Role list
        S-->>A: Roles + count
    end
    A-->>U: Formatted IAM role inventory + count
```

## Deployment Architecture

```mermaid
graph TB
    subgraph Huawei Cloud
        subgraph IAM
            R[IAM Roles / Permissions]
        end
    end
    subgraph User Side
        HC[hcloud CLI] -->|AK/SK auth| IAM
        SDK[huaweicloudsdkiam] -->|AK/SK auth| IAM
    end
```

## Security Notes

- Only read-only operation `GET /v3/roles/permissions` is invoked
- Credentials are never hardcoded in the skill; they come from the user's KooCLI configuration or environment variables
- Least-privilege IAM policy `iam:roles:listRoles` is documented in `references/iam-policies.md`
