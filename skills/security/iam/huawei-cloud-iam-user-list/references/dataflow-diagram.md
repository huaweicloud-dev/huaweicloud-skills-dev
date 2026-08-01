# Data Flow Diagram

## Architecture Overview

```mermaid
graph LR
    subgraph Agent
        A[AI Agent]
    end
    subgraph Execution
        A -->|"1. hcloud IAM KeystoneListUsers (primary)"| B[KooCLI IAM]
        A -->|"2. huaweicloudsdkiam (fallback)"| C[Python SDK]
    end
    B --> D["Huawei Cloud IAM API<br/>GET /v3/users (KeystoneListUsers)"]
    C --> D
    D --> E[(IAM Users)]
    E --> B
    E --> C
    B -->|"User list + count"| A
    C -->|"User list + count"| A
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant A as Agent
    participant C as hcloud CLI (IAM)
    participant S as Python SDK
    participant I as IAM Service

    U->>A: List my IAM users
    A->>A: Check prerequisites (hcloud, credentials)
    A->>C: hcloud IAM KeystoneListUsers --cli-region=cn-north-4
    C->>I: GET /v3/users
    I-->>C: User list + count
    C-->>A: Users + count
    alt CLI unavailable
        A->>S: keystone_list_users(KeystoneListUsersRequest)
        S->>I: GET /v3/users
        I-->>S: User list
        S-->>A: Users + count
    end
    A-->>U: Formatted IAM user inventory + count
```

## Deployment Architecture

```mermaid
graph TB
    subgraph Huawei Cloud
        subgraph IAM
            U[IAM Users / Sub-accounts]
        end
    end
    subgraph User Side
        HC[hcloud CLI] -->|AK/SK auth| IAM
        SDK[huaweicloudsdkiam] -->|AK/SK auth| IAM
    end
```

## Security Notes

- Only read-only operation `GET /v3/users` is invoked
- Credentials are never hardcoded in the skill; they come from the user's KooCLI configuration or environment variables
- Least-privilege IAM policy `iam:users:listUsers` is documented in `references/iam-policies.md`
