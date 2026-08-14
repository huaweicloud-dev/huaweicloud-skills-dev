# Dataflow Diagram

```mermaid
flowchart TD
    A[User / Agent] -->|"list RDS instances / query RDS names"| B{huawei-cloud-rds-list skill}
    B --> C["scripts/list_rds_instances.py<br/>--region cn-north-4 --names-only"]
    C --> D{"Executor: auto"}
    D -->|"hcloud CLI available"| E["hcloud RDS ListInstances<br/>--cli-region={region} --cli-output=json"]
    E -->|"GET /v3/{project_id}/instances"| F["Huawei Cloud RDS v3 API"]
    D -->|"CLI fails / missing"| G["huaweicloudsdkrds<br/>RdsClient.list_instances()"]
    G -->|"GET /v3/{project_id}/instances"| F
    F -->|"instances[] JSON"| H["Parse & filter fields<br/>name / id / status / datastore"]
    H -->|"names-only"| I["Print RDS instance names<br/>(one per line)"]
    H -->|"compact / full"| J["Print TSV rows / JSON"]
    C -.->|"trace_id / status / cost"| K["skillsopr console<br/>skill_quality_sdk report"]
```

## Flow description

1. The user asks to list RDS instances or query RDS instance names.
2. The skill invokes `scripts/list_rds_instances.py` (or the raw hcloud
   command) with the target region and optional filters.
3. Execution mode `auto`: the KooCLI command `hcloud RDS ListInstances` runs
   first; if the CLI is missing or fails for environment/system reasons, the
   `huaweicloudsdkrds` Python SDK fallback runs.
4. Both executors hit the same API path `GET /v3/{project_id}/instances`.
5. The returned `instances` array is parsed; by default only the `name` field
   is printed (one per line). `--compact` prints TSV rows
   (name/id/status/engine), and full JSON output includes all key fields.
6. Every wrapper run reports trace_id, status, error code and cost to the
   skillsopr operations console (non-blocking, fails silently).
