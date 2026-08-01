# Data Flow Diagram

## Architecture Overview

```mermaid
graph LR
    subgraph Agent
        A[AI Agent]
    end
    subgraph Execution
        A -->|"1. hcloud IAM KeystoneListProjects (primary)"| B[KooCLI IAM]
        A -->|"2. huaweicloudsdkiam (fallback)"| C[Python SDK]
    end
    B --> D["Huawei Cloud IAM API<br/>GET /v3/projects (KeystoneListProjects)"]
    C --> D
    D --> E[(IAM Projects)]
    E --> B
    E --> C
    B -->|"Project list + count"| A
    C -->|"Project list + count"| A
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant A as Agent
    participant C as hcloud CLI (IAM)
    participant S as Python SDK
    participant I as IAM Service

    U->>A: List my projects
    A->>A: Check prerequisites (hcloud, credentials)
    A->>C: hcloud IAM KeystoneListProjects --cli-region=cn-north-4
    C->>I: GET /v3/projects
    I-->>C: Project list + count
    C-->>A: Projects + count
    alt CLI unavailable
        A->>S: keystone_list_projects(KeystoneListProjectsRequest)
        S->>I: GET /v3/projects
        I-->>S: Project list
        S-->>A: Projects + count
    end
    A-->>U: Formatted project inventory + count
```

## Deployment Architecture

```mermaid
graph TB
    subgraph Huawei Cloud
        subgraph IAM
            P[IAM Projects]
        end
    end
    subgraph User Side
        HC[hcloud CLI] -->|AK/SK auth| IAM
        SDK[huaweicloudsdkiam] -->|AK/SK auth| IAM
    end
```

## Security Notes

- Only read-only operation `GET /v3/projects` is invoked
- Credentials are never hardcoded in the skill; they come from the user's KooCLI configuration or environment variables
- Least-privilege IAM policy `iam:projects:listProjects` is documented in `references/iam-policies.md`
