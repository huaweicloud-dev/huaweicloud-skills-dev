# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/database/rds/huawei-cloud-rds-troubleshoot
```

This checks all items in the Huawei Cloud Skill Specification (structure,
frontmatter, required sections, naming, security).

## Functional Testing

### CLI Mode (primary)

```bash
bash scripts/test-cli-commands.sh skills/database/rds/huawei-cloud-rds-troubleshoot cli
```

Test parameters are read from `templates/test-vars.json` (`region`,
`instance_id`). Environment variables `RDS_REGION` and `RDS_INSTANCE_ID`
override the JSON values. `instance_id` defaults to empty: the script
**validates** any configured ID against `ListInstances` (a stale ID is
discarded), then auto-discovers the first ACTIVE instance in the region.
Instance-scoped cases (TC-07..TC-13) are **skipped** when the project has
no RDS instances — the run still exits 0.

### SDK Mode (fallback)

```bash
bash scripts/test-cli-commands.sh skills/database/rds/huawei-cloud-rds-troubleshoot sdk
```

Requires `huaweicloudsdkrds` installed and AK/SK in the environment.

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | Instance list | `hcloud RDS ListInstances --cli-region=cn-north-4` |
| 2 | Instance detail | `hcloud RDS ListInstances --cli-region=cn-north-4 --id={instance_id}` |
| 3 | Replication status | `hcloud RDS ShowReplicationStatus --cli-region=cn-north-4 --instance_id={instance_id}` |
| 4 | Storage usage | `hcloud RDS ShowStorageUsedSpace --cli-region=cn-north-4 --instance_id={instance_id}` |
| 5 | Slow logs (window) | `hcloud RDS ListSlowLogs --cli-region=cn-north-4 --instance_id={instance_id} --start_date={ts} --end_date={ts}` |
| 6 | Error logs (window) | `hcloud RDS ListErrorLogsNew --cli-region=cn-north-4 --instance_id={instance_id} --start_date={ts} --end_date={ts}` |
| 7 | Configurations | `hcloud RDS ListConfigurations --cli-region=cn-north-4` |
| 8 | Instance parameters | `hcloud RDS ShowInstanceConfiguration --cli-region=cn-north-4 --instance_id={instance_id}` |
| 9 | Backups | `hcloud RDS ListBackups --cli-region=cn-north-4 --instance_id={instance_id}` |
| 10 | Diagnosis summary | `hcloud RDS ListInstanceDiagnosis --cli-region=cn-north-4 --engine=mysql` |
| 11 | Diagnosis detail | `hcloud RDS ListInstancesInfoDiagnosis --cli-region=cn-north-4 --engine=mysql --diagnosis=high_pressure` |

## Expected Results

- All read-only commands return HTTP 200 with valid JSON.
- Empty results are valid (no slow logs / error logs / instances in the
  project).
- `ListInstances` response contains an `instances` array; each item's `name`,
  `id`, `status`, `datastore.type` and `volume.size` are present.
- `ShowReplicationStatus` returns `replication_status` (`normal`/`abnormal`).
- `ShowStorageUsedSpace` returns `used` (GB).
- `ListInstanceDiagnosis` returns `diagnosis_info` with counts per item.
- Error responses from the API (`error_code`/`error_msg`) are treated as
  failures, not passes.
