---
name: huawei-cloud-dcs-query
description: >
  Query Huawei Cloud DCS (Distributed Cache Service) instances, configurations,
  backups, slow logs, big key/hot key scan tasks, migration tasks, ACL accounts,
  IP whitelists, tags, quotas, and instance statistics. Provides read-only
  inspection capabilities for daily operations, performance troubleshooting,
  and compliance auditing.
  Triggers include: DCS query, list DCS instances, check Redis instance status,
  view cache configuration, backup records, slow logs, big key analysis,
  hot key analysis, migration task, ACL account, IP whitelist, instance quota,
  list DCS, query DCS, show DCS, DCS instance, Redis instance, 分布式缓存,
  DCS查询, DCS实例查询, 缓存实例.
tags:
  - huawei-cloud
  - dcs
  - query
  - redis
  - inspection
---

# Huawei Cloud DCS Query Skill

## Overview

This skill provides comprehensive read-only query capabilities for Huawei Cloud DCS (Distributed Cache Service, i.e. managed Redis / Memcached). It covers instance listing and detail inspection,
parameter configuration review, backup/restore records, slow log analysis, and big key / hot key scan tasks. It also covers migration task tracking, ACL / whitelist inspection, tag and quota
queries, and running-instance statistics.

**Architecture:**

```
Agent → hcloud CLI (primary) → Huawei Cloud DCS API
       ↘ Python SDK (fallback) ↗
```

**Applicable Scenarios:**

- Daily DCS instance health inspection
- Cache performance troubleshooting (slow log / big key / hot key analysis)
- Backup policy and restore record verification
- Instance configuration audit and compliance check
- Migration task status tracking
- ACL account and IP whitelist security review
- Quota and tag inventory

## Prerequisites

1. **hcloud CLI** installed and authenticated — See `references/cli-installation-guide.md`
2. **Python 3.8+** with `huaweicloudsdkdcs` package (SDK fallback)
3. **Huawei Cloud AK/SK** configured via environment variables or `hcloud configure set`
4. **IAM permissions** — `DCS ReadOnlyAccess` or finer-grained policy — See `references/iam-policies.md`

## Workflow

1. **Identify query scope** — Determine which DCS aspect to inspect (instances, configurations, backups, logs, scan tasks, migration, ACL, whitelist, quota, tags)
2. **Execute query** — Run the appropriate CLI command (primary) or SDK call (fallback)
3. **Review results** — Analyze output for anomalies, performance issues, or compliance gaps
4. **Report findings** — Summarize key observations and recommendations

## Core Commands

### Instance Queries

| Purpose | Command |
|---------|---------|
| List all DCS instances | `hcloud DCS ListInstances --cli-region={region}` |
| List instances with filter | `hcloud DCS ListInstances --cli-region={region} --name={name} [--status={status}] [--limit={limit}] [--offset={offset}]` |
| Show instance details | `hcloud DCS ShowInstance --cli-region={region} --instance_id={instance_id}` |
| List instance status counts | `hcloud DCS ListNumberOfInstancesInDifferentStatus --cli-region={region}` |
| List running instance statistics | `hcloud DCS ListStatisticsOfRunningInstances --cli-region={region}` |
| List available AZs | `hcloud DCS ListAvailableZones --cli-region={region}` |
| List maintenance windows | `hcloud DCS ListMaintenanceWindows --cli-region={region}` |
| Show tenant quota | `hcloud DCS ShowQuotaOfTenant --cli-region={region}` |
| List group replication info | `hcloud DCS ListGroupReplicationInfo --cli-region={region} --instance_id={instance_id}` |

### Configuration Queries

| Purpose | Command |
|---------|---------|
| List instance configuration parameters | `hcloud DCS ListConfigurations --cli-region={region} --instance_id={instance_id}` |
| List configuration change history | `hcloud DCS ListConfigHistories --cli-region={region} --instance_id={instance_id} [--limit={limit}]` |

### Backup / Restore Queries

| Purpose | Command |
|---------|---------|
| List backup records | `hcloud DCS ListBackupRecords --cli-region={region} --instance_id={instance_id} [--limit={limit}]` |
| List restore records | `hcloud DCS ListRestoreRecords --cli-region={region} --instance_id={instance_id} [--limit={limit}]` |

### Log Queries

| Purpose | Command |
|---------|---------|
| List slow logs | `hcloud DCS ListSlowlog --cli-region={region} --instance_id={instance_id} --start_time={start_time} --end_time={end_time} [--limit={limit}]` |
| List Redis run logs | `hcloud DCS ListRedislog --cli-region={region} --instance_id={instance_id} --log_type=run [--limit={limit}]` |

### Big Key / Hot Key Scan Queries

| Purpose | Command |
|---------|---------|
| List big key scan tasks | `hcloud DCS ListBigkeyScanTasks --cli-region={region} --instance_id={instance_id} [--status={status}]` |
| Show big key autoscan config | `hcloud DCS ShowBigkeyAutoscanConfig --cli-region={region} --instance_id={instance_id}` |
| List hot key scan tasks | `hcloud DCS ListHotKeyScanTasks --cli-region={region} --instance_id={instance_id} [--status={status}]` |
| Show hot key autoscan config | `hcloud DCS ShowHotkeyAutoscanConfig --cli-region={region} --instance_id={instance_id}` |
| List diagnosis tasks | `hcloud DCS ListDiagnosisTasks --cli-region={region} --instance_id={instance_id}` |

### Migration Queries

| Purpose | Command |
|---------|---------|
| List migration tasks | `hcloud DCS ListMigrationTask --cli-region={region} [--name={name}]` |
| Show migration task detail | `hcloud DCS ShowMigrationTask --cli-region={region} --task_id={task_id}` |

### Security Queries (ACL / Whitelist)

| Purpose | Command |
|---------|---------|
| List ACL accounts | `hcloud DCS ListAclAccounts --cli-region={region} --instance_id={instance_id}` |
| Show IP whitelist | `hcloud DCS ShowIpWhitelist --cli-region={region} --instance_id={instance_id}` |

### Tag Queries

| Purpose | Command |
|---------|---------|
| List tenant-level tags | `hcloud DCS ListTagsOfTenant --cli-region={region}` |
| Show instance tags | `hcloud DCS ShowTags --cli-region={region} --instance_id={instance_id}` |

### SDK Fallback Examples

When CLI is unavailable, use the Python SDK:

```python
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkdcs.v2.region.dcs_region import DcsRegion
from huaweicloudsdkdcs.v2 import dcs_client
from huaweicloudsdkdcs.v2.model import ListInstancesRequest

credentials = BasicCredentials() \
    .with_ak(os.getenv("HUAWEI_ACCESS_KEY")) \
    .with_sk(os.getenv("HUAWEI_SECRET_KEY")) \
    .with_project_id("{project_id}")

client = dcs_client.DcsClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(DcsRegion.value_of("{region}")) \
    .build()

request = ListInstancesRequest()
request.limit = 100
response = client.list_instances(request)
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `{instance_id}` | Conditional | DCS instance ID (required for detail/config/backup/log/scan/ACL/whitelist/tag commands) | `51bb645e-d27f-465d-8192-c912d134756c` |
| `{task_id}` | Conditional | Migration task ID (required for ShowMigrationTask) | `ff808082...` |
| `{start_time}` / `{end_time}` | Conditional | Time range for slow log queries, Unix millisecond timestamps (UTC) | `1598803200000` / `1599494399000` |
| `{name}` | No | Instance or migration task name filter | `dcs-eval-client` |
| `{status}` | No | Instance or scan task status filter | `RUNNING` |
| `{limit}` | No | Maximum records to return | `100` |
| `{offset}` | No | Page offset | `0` |
| `{project_id}` | Conditional | Project ID (required for SDK/API) | `0a1234b56c78d9ef` |

## Reference Documents

- [CLI Installation Guide](references/cli-installation-guide.md)
- [IAM Policies](references/iam-policies.md)
- [Verification Method](references/verification-method.md)
- [Data Flow Diagram](references/dataflow-diagram.md)
- [Acceptance Criteria](references/acceptance-criteria.md)

## KooCLI Command Format Standard

```bash
hcloud DCS <Operation> --cli-region=<region> [--key=value ...]
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | `DCS` | `hcloud DCS ListInstances` |
| Operation name | PascalCase | `ListInstances`, `ShowInstance` |
| Region parameter | `--cli-region=<value>` | `--cli-region=cn-north-4` |
| Simple parameter | `--key=value` | `--instance_id=xxx` |
