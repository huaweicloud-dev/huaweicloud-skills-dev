# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/huawei-cloud-dcs-query
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### CLI Mode

```bash
bash scripts/test-cli-commands.sh skills/huawei-cloud-dcs-query cli
```

For instance-specific tests, set `DCS_INSTANCE_ID`:

```bash
DCS_INSTANCE_ID=<instance_id> bash scripts/test-cli-commands.sh skills/huawei-cloud-dcs-query cli
```

### SDK Mode (Fallback)

```bash
bash scripts/test-cli-commands.sh skills/huawei-cloud-dcs-query sdk
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | List instances | `hcloud DCS ListInstances --cli-region=cn-north-4 --limit=1` |
| 2 | List available AZs | `hcloud DCS ListAvailableZones --cli-region=cn-north-4` |
| 3 | List maintenance windows | `hcloud DCS ListMaintenanceWindows --cli-region=cn-north-4` |
| 4 | Show tenant quota | `hcloud DCS ShowQuotaOfTenant --cli-region=cn-north-4` |
| 5 | List instance status counts | `hcloud DCS ListNumberOfInstancesInDifferentStatus --cli-region=cn-north-4` |
| 6 | List running instance statistics | `hcloud DCS ListStatisticsOfRunningInstances --cli-region=cn-north-4` |
| 7 | List tenant tags | `hcloud DCS ListTagsOfTenant --cli-region=cn-north-4` |
| 8 | Show instance details | `hcloud DCS ShowInstance --cli-region=cn-north-4 --instance_id=<instance_id>` |
| 9 | List configurations | `hcloud DCS ListConfigurations --cli-region=cn-north-4 --instance_id=<instance_id>` |
| 10 | List backup records | `hcloud DCS ListBackupRecords --cli-region=cn-north-4 --instance_id=<instance_id> --limit=1` |
| 11 | List restore records | `hcloud DCS ListRestoreRecords --cli-region=cn-north-4 --instance_id=<instance_id> --limit=1` |
| 12 | List ACL accounts | `hcloud DCS ListAclAccounts --cli-region=cn-north-4 --instance_id=<instance_id>` |
| 13 | Show IP whitelist | `hcloud DCS ShowIpWhitelist --cli-region=cn-north-4 --instance_id=<instance_id>` |
| 14 | Show instance tags | `hcloud DCS ShowTags --cli-region=cn-north-4 --instance_id=<instance_id>` |
| 15 | List migration tasks | `hcloud DCS ListMigrationTask --cli-region=cn-north-4 --limit=1` |
| 16 | List slow logs | `hcloud DCS ListSlowlog --cli-region=cn-north-4 --instance_id=<instance_id> --start_time=1598803200000 --end_time=1599494399000 --limit=2` |

## Expected Results

- All query commands return HTTP 200 with valid JSON
- Empty results are valid (no instances/backups/tags in region)
- `ShowInstance`, `ListConfigurations`, `ListBackupRecords`, `ListRestoreRecords`, `ListAclAccounts`, `ShowIpWhitelist`, `ShowTags` require an existing `instance_id`
- `ListSlowlog` requires an existing `instance_id` plus `--start_time`/`--end_time` (Unix millisecond timestamps, UTC)
