# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | ListInstances returns valid response | `hcloud DCS ListInstances --cli-region={region} --limit=1` succeeds |
| 2 | ListAvailableZones returns AZ list | `hcloud DCS ListAvailableZones --cli-region={region}` succeeds |
| 3 | ListMaintenanceWindows returns window list | `hcloud DCS ListMaintenanceWindows --cli-region={region}` succeeds |
| 4 | ShowQuotaOfTenant returns quota info | `hcloud DCS ShowQuotaOfTenant --cli-region={region}` succeeds |
| 5 | ListNumberOfInstancesInDifferentStatus returns status counts | `hcloud DCS ListNumberOfInstancesInDifferentStatus --cli-region={region}` succeeds |
| 6 | ListStatisticsOfRunningInstances returns statistics | `hcloud DCS ListStatisticsOfRunningInstances --cli-region={region}` succeeds |
| 7 | ListMigrationTask returns migration task list | `hcloud DCS ListMigrationTask --cli-region={region} --limit=1` succeeds |
| 8 | ShowInstance returns details for valid instance | Requires existing instance_id |
| 9 | ListConfigurations returns config for valid instance | Requires existing instance_id |
| 10 | ListBackupRecords returns backup list | Requires existing instance_id |
| 11 | ListRestoreRecords returns restore list | Requires existing instance_id |
| 12 | ListAclAccounts returns ACL accounts | Requires existing instance_id |
| 13 | ShowIpWhitelist returns whitelist for valid instance | Requires existing instance_id |
| 14 | ShowTags returns tags for valid instance | Requires existing instance_id |
| 15 | ListSlowlog returns slow log entries | Requires existing instance_id and start/end timestamps |

## Non-Functional Criteria

| # | Criterion | Threshold |
|---|-----------|-----------|
| 1 | All commands are read-only | No create/update/delete operations |
| 2 | CLI command response time | < 10s for list operations |
| 3 | SDK fallback works when CLI unavailable | All query methods available via SDK |
| 4 | No credential hardcoding | AK/SK from environment variables only |
| 5 | IAM least privilege | ReadOnlyAccess only |

## Compliance Criteria

| # | Criterion | Check |
|---|-----------|-------|
| 1 | SKILL.md frontmatter valid | name + description + tags present |
| 2 | All required sections present | Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents |
| 3 | No version field in frontmatter | `version` key absent |
| 4 | File count <= 30 | Count all files in skill directory |
| 5 | SKILL.md line count <= 500 | Line count check |
