# Data Flow Diagram

```mermaid
flowchart TD
    U[User / Agent] --> Q{Requirement}
    Q -->|"list backups"| S[huawei-cloud-vbs-list skill]

    S --> P1{Prerequisites OK?}
    P1 -->|No| INSTALL[Install hcloud / configure AK/SK]
    INSTALL --> P1
    P1 -->|Yes| M{Execution mode}

    M -->|CLI preferred| CLI["hcloud CBR ListBackups\n--cli-region={region} [--status] [--name]\n[--resource_type] [--vault_id]\n[--start_time] [--end_time] [--limit]"]
    M -->|SDK fallback| SDK["python3 scripts/list_vbs_backups.py\n--region {region} [--status] [--name]\n[--resource-type] [--vault-id] [--limit]"]

    CLI --> AUTH{Huawei Cloud Auth\nAK/SK via profile/env}
    AUTH -->|200| API["CBR ListBackups API\nGET /v3/{project_id}/backups"]
    AUTH -->|403| PERM["Check IAM cbr:backup:list\nsee references/iam-policies.md"]

    SDK --> SDKAPI["huaweicloudsdkcbr list_backups\n(v3 path via SDK client)"]

    API --> RESP[JSON: backups / count / offset / limit]
    SDKAPI --> RESP
    RESP --> SUMMARY[Summarize: ID, Name, Status, ResourceType, CreatedAt]
    SUMMARY --> OUT[Return result to user]
```

## Description

1. The user requests a list of their VBS (Volume Backup Service) backups.
2. The skill verifies the CLI and credentials prerequisites.
3. The skill executes `hcloud CBR ListBackups` (CLI-first). If the CLI is unavailable, it falls back to the CBR SDK (`scripts/list_vbs_backups.py`).
4. Both paths call the real CBR API `GET /v3/{project_id}/backups` (VBS has been merged into CBR).
5. The JSON response is summarized into key fields and returned to the user.
