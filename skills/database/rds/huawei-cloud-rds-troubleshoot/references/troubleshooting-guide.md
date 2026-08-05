# Troubleshooting Guide — Symptom → Diagnosis → Resolution

This guide details the guided troubleshooting scenarios for
`huawei-cloud-rds-troubleshoot`. For each symptom, follow the listed steps
**in order**; run the commands, read the results, and only continue when the
outcome matches. **Never run a write operation without explicit user
confirmation.**

## Scenario 1: Instance Unreachable / Connection Refused

**Symptoms:** application cannot connect; connection timeout; login failure;
instance status not `ACTIVE`.

| Step | Action | Command |
|------|--------|---------|
| 1 | Locate the instance & check status | `hcloud RDS ListInstances --cli-region={region} --id={instance_id} --cli-output=json` |
| 2 | Check error logs for crash/startup errors | `hcloud RDS ListErrorLogsNew --cli-region={region} --instance_id={instance_id} --start_date={ts} --end_date={ts} --cli-output=json` |
| 3 | Check disk usage (STORAGE_FULL blocks writes) | `hcloud RDS ShowStorageUsedSpace --cli-region={region} --instance_id={instance_id} --cli-output=json` |
| 4 | If status is `REBOOTING`/`BACKING_UP` — wait and re-check | `hcloud RDS ListInstances --cli-region={region} --id={instance_id} --cli-output=json` |
| 5 | If status is `ERROR`/`FAILED` or logs show crash | Offer restart: `hcloud RDS StartInstanceRestartAction --cli-region={region} --instance_id={instance_id} --restart={} --cli-output=json` (**CONFIRM** — brief downtime) |

**Resolution tips:** after restart, re-check status and error logs; if the
instance is `STORAGE_FULL`, expand volume or clean data first; check
security-group/whitelist only after the instance is healthy.

## Scenario 2: Slow Queries / High CPU / Performance Degradation

**Symptoms:** slow page loads; high CPU; queries taking seconds; business
reports timing out.

| Step | Action | Command |
|------|--------|---------|
| 1 | Instance overview | `hcloud RDS ListInstances --cli-region={region} --id={instance_id} --cli-output=json` |
| 2 | Diagnosis summary | `hcloud RDS ListInstanceDiagnosis --cli-region={region} --engine=mysql --cli-output=json` |
| 3 | High-pressure / slow-SQL detail | `hcloud RDS ListInstancesInfoDiagnosis --cli-region={region} --engine=mysql --diagnosis=high_pressure --cli-output=json` |
| 4 | Slow-log analysis in the incident window | `hcloud RDS ListSlowLogs --cli-region={region} --instance_id={instance_id} --start_date={ts} --end_date={ts} --cli-output=json` |
| 5 | Inspect key parameters | `hcloud RDS ShowInstanceConfiguration --cli-region={region} --instance_id={instance_id} --cli-output=json` |

**Analysis:** rank slow-log entries by `time` and `rows_examined`. Queries
with high `rows_examined` but few `rows_sent` typically miss indexes → advise
`EXPLAIN` and index creation (done by the DBA, outside this skill). Check
`lock_wait` diagnosis for blocking. If `max_connections` is near its limit,
see Scenario 5.

## Scenario 3: Disk Full / Insufficient Capacity

**Symptoms:** `STORAGE_FULL` status; write errors "table is full"; disk alarm.

| Step | Action | Command |
|------|--------|---------|
| 1 | Check used space vs volume size | `hcloud RDS ShowStorageUsedSpace --cli-region={region} --instance_id={instance_id} --cli-output=json` + `ListInstances --id` for `volume.size` |
| 2 | Capacity diagnosis | `hcloud RDS ListInstancesInfoDiagnosis --cli-region={region} --engine=mysql --diagnosis=insufficient_capacity --cli-output=json` |
| 3 | Check backup/space pressure | `hcloud RDS ListBackups --cli-region={region} --instance_id={instance_id} --cli-output=json` |

**Resolution:** guide the user to expand storage
(`hcloud RDS StartInstanceEnlargeVolumeAction --cli-region={region}
--instance_id={instance_id} --enlarge_volume.size={new_size} --cli-output=json`
— **WRITE, CONFIRM**), clean expired backups/logs, or archive cold data.
Never delete data without user confirmation.

## Scenario 4: Primary-Standby Replication Broken

**Symptoms:** standby lag alarms; `replication_status` not `normal`;
failover required.

| Step | Action | Command |
|------|--------|---------|
| 1 | Replication status | `hcloud RDS ShowReplicationStatus --cli-region={region} --instance_id={instance_id} --cli-output=json` |
| 2 | Error logs on both nodes | `hcloud RDS ListErrorLogsNew --cli-region={region} --instance_id={instance_id} --start_date={ts} --end_date={ts} --cli-output=json` |
| 3 | (PostgreSQL) replay delay | `hcloud RDS ShowReplayDelayStatus --cli-region={region} --instance_id={instance_id} --cli-output=json` |

**Resolution:** transient lag usually recovers; persistent `abnormal` may need
failover (`hcloud RDS StartFailover --cli-region={region}
--instance_id={instance_id} --cli-output=json` — **WRITE, CONFIRM**) or
re-copy of data. Escalate to Huawei Cloud O&M if the nodes cannot sync.

## Scenario 5: Connection Limit Exceeded

**Symptoms:** "Too many connections"; `connections_exceed` diagnosis; app
pool exhaustion.

| Step | Action | Command |
|------|--------|---------|
| 1 | Diagnosis detail | `hcloud RDS ListInstancesInfoDiagnosis --cli-region={region} --engine=mysql --diagnosis=connections_exceed --cli-output=json` |
| 2 | Current `max_connections` | `hcloud RDS ShowInstanceConfiguration --cli-region={region} --instance_id={instance_id} --cli-output=json` (grep `max_connections`) |
| 3 | Tune (if safe) | `hcloud RDS UpdateInstanceConfiguration --cli-region={region} --instance_id={instance_id} --values.max_connections={new_value} --cli-output=json` (**CONFIRM**; check `value_range` and `restart_required`) |

**Analysis:** first check for connection leaks in the app (most common
cause); only then raise `max_connections` within its `value_range`.

## Scenario 6: Memory Overrun / OOM

**Symptoms:** `mem_overrun` diagnosis; instance restarts; out-of-memory in
logs.

| Step | Action | Command |
|------|--------|---------|
| 1 | Diagnosis detail | `hcloud RDS ListInstancesInfoDiagnosis --cli-region={region} --engine=mysql --diagnosis=mem_overrun --cli-output=json` |
| 2 | Error logs | `hcloud RDS ListErrorLogsNew --cli-region={region} --instance_id={instance_id} --start_date={ts} --end_date={ts} --cli-output=json` |
| 3 | Buffer pool / shared buffers | `hcloud RDS ShowInstanceConfiguration --cli-region={region} --instance_id={instance_id} --cli-output=json` |

**Resolution:** tune `innodb_buffer_pool_size` (MySQL) / `shared_buffers`
(PostgreSQL) within the instance spec, review `max_connections` × per-session
memory, or resize the flavor (write op, confirm).

## Scenario 7: Data Safety / Recovery

**Symptoms:** accidental data change; user wants a point-in-time recovery or
a manual backup before a risky change.

| Step | Action | Command |
|------|--------|---------|
| 1 | Backup inventory | `hcloud RDS ListBackups --cli-region={region} --instance_id={instance_id} --cli-output=json` |
| 2 | Pre-change safety backup | `hcloud RDS CreateManualBackup --cli-region={region} --instance_id={instance_id} --name={backup_name} --cli-output=json` (**CONFIRM**) |
| 3 | Restore to existing instance | `hcloud RDS RestoreToExistingInstance --cli-region={region} --source.instance_id={instance_id} --source.backup_id={backup_id} --target.instance_id={target_id} --cli-output=json` (**CONFIRM** — overwrites target; prefer restoring to a NEW instance when possible) |

> ⚠️ Always state clearly before a restore: the target instance's data will be
> **overwritten** by the backup. Recommend a manual backup of the target
> first.
