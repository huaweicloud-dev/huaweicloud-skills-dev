---
name: huawei-cloud-rds-troubleshoot
description: |
  Full-scenario intelligent assistant for Huawei Cloud RDS (Relational
  Database Service, MySQL + PostgreSQL). Provides basic RDS Q&A, SQL
  performance optimization (slow-log analysis), daily instance operations,
  online fault location and troubleshooting, parameter tuning, and
  backup/restore guidance. Core scenario is ONLINE FAULT TROUBLESHOOTING:
  the skill guides the user step by step through symptoms (unreachable
  instance, slow queries, disk full, replication broken, connection limit
  exceeded, memory overrun) to diagnosis and resolution. Execution is
  CLI-first via `hcloud RDS ... --cli-region={region}` (KooCLI), falling
  back to the huaweicloudsdkrds Python SDK and then REST API. Output is
  interactive and guided — one diagnostic step at a time, with user
  confirmation before any mutating action (restart, parameter change,
  manual backup, restore).
  Triggers include: "RDS troubleshooting", "RDS故障排查", "数据库连不上",
  "RDS slow query", "RDS慢SQL", "RDS磁盘满", "RDS instance down",
  "RDS主备不同步", "RDS参数调优", "RDS备份恢复", "RDS error log",
  "RDS storage full", "troubleshoot RDS", "RDS诊断", "数据库性能优化",
  "RDS连接数满", "MySQL/PostgreSQL fault".
tags:
  - huawei-cloud
  - rds
  - troubleshooting
  - database
  - diagnosis
---

# Huawei Cloud RDS Troubleshoot Skill

## Overview

This skill provides **full-scenario intelligent service for Huawei Cloud RDS
(Relational Database Service)** for **MySQL** and **PostgreSQL** engines. It
covers:

1. **Basic RDS Q&A** — explain instance concepts, status meanings, HA
   architecture, and common terms from live instance data.
2. **SQL performance optimization** — locate slow queries via slow logs,
   correlate with CPU/connection pressure, and suggest index/parameter
   improvements.
3. **Daily instance operations** — inventory, status, storage, replication,
   and configuration inspection.
4. **Online fault location & troubleshooting (core scenario)** — guided
   step-by-step diagnosis of the most common production faults: instance
   unreachable/crash, slow SQL & high pressure, disk full, primary-standby
   replication failure, connection limit exceeded, and memory overrun.
5. **Parameter tuning** — inspect current parameter values, compare templates,
   and modify parameters (with user confirmation).
6. **Backup/restore guidance** — list backups, create manual backups, and
   guide restore flows (with user confirmation before write operations).

**Execution mode:** CLI-first (`hcloud RDS <Operation> --cli-region={region}`),
falling back to the `huaweicloudsdkrds` Python SDK, then REST API.

**Output form:** interactive guided troubleshooting — one diagnostic step at a
time, presenting findings and the next recommended step, never dumping raw
JSON at the user.

**Architecture:**

```text
User/Agent → hcloud CLI (KooCLI RDS, primary) → Huawei Cloud RDS v3 API
           ↘ huaweicloudsdkrds Python SDK (fallback)      ↗
           ↘ REST API (curl, last resort)                 ↗
```

**API base (all operations below are KooCLI `RDS` operations against the v3
API; paths verified from KooCLI operation definitions):**

| Operation | Method | API Path |
|-----------|--------|----------|
| List instances | GET | `/v3/{project_id}/instances` |
| Show replication status | GET | `/v3/{project_id}/instances/{instance_id}/replication/status` |
| Show storage used space | GET | `/v3/{project_id}/instances/{instance_id}/storage-used-space` |
| List slow logs | GET | `/v3/{project_id}/instances/{instance_id}/slowlog` |
| List error logs | GET | `/v3/{project_id}/instances/{instance_id}/errorlog` |
| List configurations | GET | `/v3/{project_id}/configurations` |
| Show instance configuration | GET | `/v3/{project_id}/instances/{instance_id}/configurations` |
| List backups | GET | `/v3/{project_id}/backups` |
| List instance diagnosis | GET | `/v3/{project_id}/instances/diagnosis` |
| Restart instance | POST | `/v3/{project_id}/instances/{instance_id}/action` |

> **能力边界（Capability Boundary）：**
> 本 Skill **只针对华为云 RDS（MySQL/PostgreSQL）**，提供查询、诊断、运维、
> 参数调优与备份恢复引导。**不** 创建/删除实例、**不** 直接执行 DDL/DML、
> **不** 修改数据库账号密码、**不** 管理 DRS 迁移任务。所有写操作
> （重启、改参数、手动备份、恢复）都必须先得到用户明确确认。若用户询问
> 上述范围外的操作（如"帮我删掉这个实例""直接执行 UPDATE"），请明确告知
> 本 Skill 不提供该能力，并给出建议（如使用 RDS 控制台或对应管理类 skill）。

## Prerequisites

1. **hcloud CLI (KooCLI) v3.2.0+** installed and authenticated with an AK/SK
   profile — see `references/cli-installation-guide.md`.
2. **Python 3.8+** with `huaweicloudsdkrds` (SDK fallback only; optional when
   CLI is available).
3. **IAM permissions** — read checks need `rds:instance:list`,
   `rds:instance:get`, `rds:backup:list`, `rds:configuration:list`,
   `rds:configuration:get` (or system policy `RDS ReadOnlyAccess`); write
   operations additionally need `rds:instance:action`, `rds:backup:create`,
   `rds:configuration:update` (or `RDS FullAccess`). See
   `references/iam-policies.md`.
4. The region of the target instance(s) — pass `--cli-region={region}` on
   every command (default `cn-north-4`).
5. The target instance ID (`{instance_id}`) — obtainable from
   `hcloud RDS ListInstances --cli-region={region}`.

## Workflow

### A. Guided Fault Troubleshooting (Core Scenario)

Follow this decision flow **step by step**. Run the listed command for the
current step, read the result, then continue per the outcome. Never jump
ahead; never run mutating commands without explicit user confirmation.

```text
Symptom reported by user
   │
   ▼
Step 1  Locate the instance
   │     hcloud RDS ListInstances --cli-region={region} [--id={instance_id}]
   │     → is the instance in the list? what is "status"?
   │
   ▼
Step 2  Classify the symptom (see tables below)
   │
   ├── Instance unreachable / status not ACTIVE
   │     → check error logs (ListErrorLogsNew), check storage (Step 3),
   │       then offer restart (Step 8, CONFIRM)
   ├── Slow queries / high pressure
   │     → diagnosis summary (Step 5), slow logs (Step 6), parameter tuning (Step 7)
   ├── Disk full / storage alarms
   │     → storage check (Step 3), diagnosis insufficient_capacity (Step 5)
   ├── Primary-standby replication broken
   │     → replication status (Step 4)
   ├── Connection limit exceeded / memory overrun
   │     → diagnosis connections_exceed / mem_overrun (Step 5), tuning (Step 7)
   └── Data safety / recovery concerns
         → backup list (Step 9), restore guidance (Step 10)
   │
   ▼
Step 3..10  Execute the matching diagnostic/action steps below
   │
   ▼
Step 11  Summarize: root cause + evidence + resolution taken + prevention
```

### B. Step Reference

1. **Locate the instance** — `ListInstances` (with `--id` for exact match).
2. **Confirm region and instance ID** with the user before any instance-scoped
   query; if the user gives an instance name, resolve it to an ID via
   `ListInstances --name={name}` first.
3. **Check storage usage** — `ShowStorageUsedSpace`; compare `used` against
   the volume `size` from `ListInstances`.
4. **Check replication/HA** — `ShowReplicationStatus`; for PostgreSQL also
   `ShowReplayDelayStatus` when applicable.
5. **Run intelligent diagnosis** — `ListInstanceDiagnosis` for the summary,
   then `ListInstancesInfoDiagnosis --diagnosis={item}` for detail.
6. **Analyze slow/error logs** — `ListSlowLogs` / `ListErrorLogsNew` with the
   incident time window; download files with `ListSlowLogFile` /
   `DownloadSlowlog` / `DownloadErrorlog` for deep analysis.
7. **Parameter tuning** — `ShowInstanceConfiguration` to inspect,
   `ListConfigurations` to compare templates, then
   `UpdateInstanceConfiguration` / `UpdatePostgresqlParameterValue`
   (**CONFIRM** with the user; note `restart_required`).
8. **Restart instance** — `StartInstanceRestartAction` (**CONFIRM**; explain
   downtime impact first).
9. **Backup list** — `ListBackups`; verify latest successful backup time and
   status before any recovery discussion.
10. **Backup/restore** — `CreateManualBackup` for a pre-change safety backup
    (**CONFIRM**), `RestoreToExistingInstance` / `RestoreExistInstance` for
    recovery (**CONFIRM**; explain that restore overwrites the target).
11. **Summarize** — root cause, evidence (command outputs), resolution, and
    prevention tips.

### C. Common Fault → Step Map

| Symptom | Primary steps | Key commands |
|---------|---------------|--------------|
| Instance unreachable / connection refused | 1, 2, 6, 8 | `ListInstances`, `ListErrorLogsNew`, `StartInstanceRestartAction` |
| Slow queries / high CPU | 1, 2, 5, 6, 7 | `ListInstanceDiagnosis`, `ListSlowLogs`, `ShowInstanceConfiguration` |
| Disk full / insufficient capacity | 1, 2, 3, 5, 9 | `ShowStorageUsedSpace`, `ListInstancesInfoDiagnosis --diagnosis=insufficient_capacity` |
| Primary-standby replication broken | 1, 2, 4, 6 | `ShowReplicationStatus`, `ListErrorLogsNew` |
| Connection limit exceeded | 1, 2, 5, 7 | `ListInstancesInfoDiagnosis --diagnosis=connections_exceed`, tuning `max_connections` |
| Memory overrun | 1, 2, 5, 6, 7 | `ListInstancesInfoDiagnosis --diagnosis=mem_overrun`, `ListSlowLogs` |
| Data safety / recovery | 9, 10 | `ListBackups`, `CreateManualBackup`, `RestoreToExistingInstance` |

## Core Commands

> KooCLI format: `hcloud <Service> <Operation> --cli-region=<region> [--key=value]`

### 1. Instance inventory & status (fault triage start)

```bash
hcloud RDS ListInstances --cli-region={region} --cli-output=json
# Filter by engine:
hcloud RDS ListInstances --cli-region={region} --datastore_type=MySQL --cli-output=json
hcloud RDS ListInstances --cli-region={region} --datastore_type=PostgreSQL --cli-output=json
```

Compact status table (name, id, status, engine, volume):

```bash
hcloud RDS ListInstances --cli-region={region} --cli-output=json \
  | jq -r '.instances[] | [.name, .id, .status, .datastore.type, .volume.size] | @tsv'
```

Instance `status` values include: `ACTIVE`, `BUILD`, `REBOOTING`,
`RESTORING`, `BACKING_UP`, `STORAGE_FULL`, `ERROR`, `FAILED`, `DELETING`.

### 2. Instance detail (spec, HA, nodes)

```bash
hcloud RDS ListInstances --cli-region={region} --id={instance_id} --cli-output=json
```

There is no standalone `ShowInstance` KooCLI operation; `ListInstances
--id={instance_id}` returns the exact instance with `type` (Ha/Single),
`nodes[].role` (master/slave), `nodes[].availability_zone`,
`ha.replication_mode`, `volume`, and `datastore`.

### 3. Storage usage / disk-full check

```bash
hcloud RDS ShowStorageUsedSpace --cli-region={region} --instance_id={instance_id} --cli-output=json
```

`used` is returned in GB; compare with the volume `size` from
`ListInstances`. If `used` is close to `size` (or instance status is
`STORAGE_FULL`), guide the user to expand the volume
(`StartInstanceEnlargeVolumeAction`, write op — confirm) or clean up data.

### 4. Replication / HA status

```bash
hcloud RDS ShowReplicationStatus --cli-region={region} --instance_id={instance_id} --cli-output=json
```

`replication_status` values: `normal` (healthy), `abnormal` (broken —
check error logs, network/security-group, then consider failover
`StartFailover`, write op — confirm), `unavailable`.

### 5. Intelligent diagnosis summary & detail

```bash
hcloud RDS ListInstanceDiagnosis --cli-region={region} --engine=mysql --cli-output=json
hcloud RDS ListInstanceDiagnosis --cli-region={region} --engine=postgresql --cli-output=json
```

Diagnosis items (`ListInstancesInfoDiagnosis --diagnosis={item}`):
`high_pressure`, `lock_wait`, `insufficient_capacity`,
`slow_sql_frequency`, `disk_performance_cap`, `mem_overrun`,
`age_exceed`, `connections_exceed`.

```bash
hcloud RDS ListInstancesInfoDiagnosis --cli-region={region} --engine=mysql \
  --diagnosis=high_pressure --cli-output=json
```

### 6. Slow SQL & error log analysis

Time format: `yyyy-mm-ddThh:mm:ss+0000` (UTC — the RDS API rejects the `Z`
suffix, e.g. `2026-08-05T00:00:00+0000`). Only logs from the **last month**
are queryable.

```bash
hcloud RDS ListSlowLogs --cli-region={region} --instance_id={instance_id} \
  --start_date={start_ts} --end_date={end_ts} --cli-output=json
hcloud RDS ListErrorLogsNew --cli-region={region} --instance_id={instance_id} \
  --start_date={start_ts} --end_date={end_ts} --cli-output=json
# Slow-log file listing + download link:
hcloud RDS ListSlowLogFile --cli-region={region} --instance_id={instance_id} --cli-output=json
hcloud RDS DownloadSlowlog --cli-region={region} --instance_id={instance_id} --cli-output=json
hcloud RDS DownloadErrorlog --cli-region={region} --instance_id={instance_id} --cli-output=json
```

Slow-log entries include `query_sample`, `time` (execution seconds),
`lock_time`, `rows_sent`, `rows_examined`, `database`, `type`. Guide the
user to optimize queries with high `rows_examined` / `time` (missing
indexes, full table scans) and to correlate with
`--diagnosis=slow_sql_frequency`.

### 7. Parameter tuning

```bash
# List parameter templates (default + custom):
hcloud RDS ListConfigurations --cli-region={region} --cli-output=json
# Inspect the parameters of a specific instance:
hcloud RDS ShowInstanceConfiguration --cli-region={region} --instance_id={instance_id} --cli-output=json
```

Each parameter shows `value`, `value_range`, `restart_required`, `readonly`.
Common tuning targets for troubleshooting: `max_connections` (connection
limit exceeded), `innodb_buffer_pool_size` / `shared_buffers` (memory),
`slow_query_log` & `long_query_time` (slow SQL capture).

Modify parameters (**WRITE — confirm with the user first; note
`restart_required`**):

```bash
# MySQL / SQLServer (general):
hcloud RDS UpdateInstanceConfiguration --cli-region={region} --instance_id={instance_id} \
  --values.max_connections=500 --cli-output=json
# PostgreSQL (single parameter):
hcloud RDS UpdatePostgresqlParameterValue --cli-region={region} \
  --instance_id={instance_id} --name=max_connections --value=500 --cli-output=json
```

### 8. Restart instance (fault recovery)

```bash
hcloud RDS StartInstanceRestartAction --cli-region={region} \
  --instance_id={instance_id} --restart={} --cli-output=json
```

> ⚠️ **WRITE operation.** Always explain the downtime impact and get explicit
> user confirmation before running. Prefer checking logs/status first.

### 9. Backup list

```bash
hcloud RDS ListBackups --cli-region={region} --instance_id={instance_id} --cli-output=json
# Type filter: auto | manual | fragment | incremental
hcloud RDS ListBackups --cli-region={region} --instance_id={instance_id} \
  --backup_type=manual --cli-output=json
```

Verify the latest `COMPLETED` backup and its `begin_time`/`end_time` before
any recovery discussion.

### 10. Backup / restore

```bash
# Create a manual backup before any risky change (WRITE — confirm):
hcloud RDS CreateManualBackup --cli-region={region} \
  --instance_id={instance_id} --name={backup_name} --cli-output=json
# Restore a backup to an existing instance (WRITE — confirm; overwrites target):
hcloud RDS RestoreToExistingInstance --cli-region={region} \
  --source.instance_id={instance_id} --source.backup_id={backup_id} \
  --target.instance_id={target_instance_id} --cli-output=json
```

Backup name: 4–64 chars, start with a letter, only letters/digits/`-`/`_`.

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region of the instance | `cn-north-4` |
| `{instance_id}` | Yes (instance-scoped ops) | RDS instance ID (`...in01` suffix) | `a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4in01` (synthetic example) |
| `{start_ts}` / `{end_ts}` | Yes (log queries) | UTC window `yyyy-mm-ddThh:mm:ss+0000`, ≤ 1 month back | `2026-08-05T00:00:00+0000` |
| `{engine}` | No | `MySQL` / `PostgreSQL` (diagnosis & list filter) | `mysql` |
| `{diagnosis}` | No | Diagnosis item for `ListInstancesInfoDiagnosis` | `high_pressure` |
| `{backup_name}` | No | Manual backup name (4–64 chars) | `pre-fix-backup-0805` |
| `{backup_id}` | No | Backup ID for restore | `e0d7747a016d469cb83c89c1cf05753ebr01` |

## KooCLI Command Format Standard

The KooCLI command format is:

`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]`

> Note: this is a generic format template, not an executable command — replace
> `<Service>`, `<Operation>`, `<region>` and the parameters with real values
> (e.g. `hcloud RDS ListInstances --cli-region=cn-north-4`).

- Service name: `RDS` (starts with uppercase).
- Operation name: PascalCase — `ListInstances`, `ShowReplicationStatus`,
  `ListSlowLogs`, `UpdateInstanceConfiguration`.
- Region: always pass `--cli-region=<region>`.
- Simple parameters use `--key=value`, e.g. `--instance_id=...`.
- Nested/object parameters use indexed keys, e.g. `--values.max_connections=500`
  or `--source.instance_id=...`.

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Least-privilege IAM permissions
- [CLI Installation Guide](references/cli-installation-guide.md) — hcloud CLI setup and authentication
- [Troubleshooting Guide](references/troubleshooting-guide.md) — Detailed symptom→diagnosis→resolution scenarios
- [Verification Method](references/verification-method.md) — How to verify the skill works
- [Dataflow Diagram](references/dataflow-diagram.md) — Request flow diagram
- [Acceptance Criteria](references/acceptance-criteria.md) — Acceptance test checklist
