# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | `ListInstances` returns valid response | `hcloud RDS ListInstances --cli-region={region}` succeeds and returns the instance list |
| 2 | Instance detail via `--id` | `hcloud RDS ListInstances --cli-region={region} --id={instance_id}` returns name/status/datastore/volume/nodes |
| 3 | Replication status query works | `hcloud RDS ShowReplicationStatus --cli-region={region} --instance_id={instance_id}` returns `replication_status` |
| 4 | Storage usage query works | `hcloud RDS ShowStorageUsedSpace --cli-region={region} --instance_id={instance_id}` returns `used` |
| 5 | Slow-log query works | `hcloud RDS ListSlowLogs --cli-region={region} --instance_id={instance_id} --start_date={ts} --end_date={ts}` succeeds (empty list is valid) |
| 6 | Error-log query works | `hcloud RDS ListErrorLogsNew --cli-region={region} --instance_id={instance_id} --start_date={ts} --end_date={ts}` succeeds |
| 7 | Parameter inspection works | `hcloud RDS ShowInstanceConfiguration --cli-region={region} --instance_id={instance_id}` returns `configuration_parameters` |
| 8 | Backup listing works | `hcloud RDS ListBackups --cli-region={region} --instance_id={instance_id}` returns backups |
| 9 | Intelligent diagnosis works | `hcloud RDS ListInstanceDiagnosis --cli-region={region} --engine=mysql` returns `diagnosis_info` |
| 10 | Guided flow produces step-by-step output | Troubleshooting scenario yields sequential diagnosis steps with a final summary |

## Write-Operation Criteria (user-confirmed only)

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | Restart requires confirmation | `StartInstanceRestartAction` documented as WRITE with explicit confirmation note |
| 2 | Parameter modify requires confirmation | `UpdateInstanceConfiguration` / `UpdatePostgresqlParameterValue` documented as WRITE with confirmation note |
| 3 | Manual backup requires confirmation | `CreateManualBackup` documented as WRITE with confirmation note |
| 4 | Restore requires confirmation | `RestoreToExistingInstance` documented as WRITE with overwrite warning |

## Non-Functional Criteria

| # | Criterion | Threshold |
|---|-----------|-----------|
| 1 | Read-only commands dominate the flow | All diagnosis steps are read-only |
| 2 | CLI response time | < 10s per query command |
| 3 | SDK fallback documented | `huaweicloudsdkrds` usage shown in `references/cli-installation-guide.md` |
| 4 | No credential hardcoding | AK/SK from environment variables or hcloud profile only |
| 5 | IAM least privilege | Read-only actions + narrowly-scoped write actions; `RDS ReadOnlyAccess` as default system policy |

## Compliance Criteria

| # | Criterion | Check |
|---|-----------|-------|
| 1 | SKILL.md frontmatter valid | name + description (feature summary + triggers) + tags present |
| 2 | All required sections present | Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents, KooCLI Command Format Standard |
| 3 | No version field in frontmatter | `version` key absent |
| 4 | Directory name matches frontmatter name | `huawei-cloud-rds-troubleshoot` |
| 5 | File count <= 30 | Count all files in skill directory |
| 6 | SKILL.md line count <= 500 | Line count check |
| 7 | references/ file names are kebab-case | `iam-policies.md`, `cli-installation-guide.md`, etc. |
