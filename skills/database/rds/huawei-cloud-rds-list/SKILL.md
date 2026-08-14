---
name: huawei-cloud-rds-list
description: |
  Query the list of Huawei Cloud RDS (Relational Database Service, 云数据库)
  instances under the current tenant / project and return the RDS instance
  NAMES. By default the skill prints only the instance names (one per line);
  with extra flags it also returns id, status, engine type, flavor, private
  IPs and created time. Supports filtering by instance name, id, type
  (Single/Ha/Replica), datastore engine (MySQL/PostgreSQL/SQLServer/MariaDB)
  and VPC, plus pagination via limit/offset. Uses the KooCLI command
  `hcloud RDS ListInstances --cli-region={region}` (primary) or the
  huaweicloudsdkrds Python SDK (fallback). Read-only — never creates,
  modifies, deletes, restarts or stops any RDS instance.
  Use this skill whenever the user wants to list/inspect the RDS instances of
  the tenant or query the RDS instance name list, e.g. for database inventory,
  daily inspection, or cost review.
  Triggers include: "list RDS", "RDS list", "query RDS names", "RDS实例列表",
  "查询RDS", "RDS实例名称", "rds list", "how many RDS", "RDS inventory",
  "list database instances", "云数据库实例".
tags:
  - huawei-cloud
  - rds
  - database
  - list
  - query
---

# Huawei Cloud RDS List Skill

## Overview

This skill queries the list of **Relational Database Service (云数据库 RDS)**
instances under the current Huawei Cloud tenant / project and returns their key
attributes — by default only the **RDS instance names** (`name`, one per
line), optionally together with `id`, `status`, `type`, `engine`, `version`,
`flavor`, `private_ips` and `created` time. It is a read-only inspection
skill: it never creates, modifies, deletes, restarts or stops any database
instance.

**Architecture:**

```text
Agent → hcloud CLI (KooCLI, RDS ListInstances, primary) → Huawei Cloud RDS v3 API
       ↘ huaweicloudsdkrds Python SDK (fallback)                  ↗
```

**API path (verified from `huaweicloudsdkrds` v3 SDK `_list_instances_http_info`):**

| Operation | Method | API Path |
|-----------|--------|----------|
| List RDS instances | GET | `/v3/{project_id}/instances` |

**Execution-quality reporting:** every invocation of
`scripts/list_rds_instances.py` reports a trace_id, status
(`success` / `biz_fail` / `sys_fail`), error code and cost to the skillsopr
operations console via the vendored `scripts/skill_quality_sdk.py`. Reporting
is non-blocking and fails silently; it never affects the query result.

**Applicable Scenarios:**

- Database inventory: "list all RDS instances of this tenant" or "show me the RDS name list"
- Daily inspection: snapshot of all RDS instances with their status and engine
- Cost review: enumerate RDS instances and their flavors to spot unused or oversized databases
- Fast lookup: retrieve the exact RDS instance name/id for follow-up operations
- Auto detection: periodic checks that detect new/stopped/error RDS instances

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询 RDS 实例列表**。不创建/删除/修改/重启/停止 RDS 实例，
> 也不查询备份、参数组、日志等其它 RDS 资源。
> 若用户询问"创建/删除 RDS"、"重启 RDS"、"查询备份"等，
> 请明确告知本 Skill 不提供该能力。

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **Python 3.8+** with `huaweicloudsdkrds` package installed (SDK fallback only)
3. **IAM permissions** — `rds:instance:list` (or the system policy
   `RDS ReadOnlyAccess`) is required to list RDS instances. See `references/iam-policies.md`
4. A region where the tenant owns RDS instances; specify it with `--cli-region`

## Workflow

1. **Identify the intent** — Confirm the user wants to list RDS instances
   (and optionally the filters: name, id, type, engine, or name-only output).
2. **Confirm region** — Default `cn-north-4`; let the user override with another
   region if needed.
3. **Run the query** — Use the CLI command below with the requested filters.
4. **Present the results** — By default output only the RDS instance names
   (one per line); with `--compact` or full JSON output show the extra fields.
5. **Handle errors** — If the CLI fails (credentials/permissions/network), retry
   with the SDK fallback described in `references/verification-method.md`.

## Core Commands

> KooCLI format: `hcloud <Service> <Operation> --cli-region=<region> [--key=value]`

### List all RDS instances (full JSON)

```bash
hcloud RDS ListInstances --cli-region={region} --cli-output=json
```

### List only the RDS instance names

```bash
hcloud RDS ListInstances --cli-region={region} --cli-query="instances[].name"
```

### Compact fields: name, id, status, engine

```bash
hcloud RDS ListInstances --cli-region={region} --cli-output=json \
  | jq -r '.instances[] | [.name, .id, .status, .datastore.type] | @tsv'
```

### Filter by engine / type / name / VPC

```bash
hcloud RDS ListInstances --cli-region={region} --datastore_type=MySQL --cli-output=json
hcloud RDS ListInstances --cli-region={region} --type=Ha --cli-output=json
hcloud RDS ListInstances --cli-region={region} --name={instance-name} --cli-output=json
hcloud RDS ListInstances --cli-region={region} --vpc_id={vpc-id} --cli-output=json
```

### Pagination

```bash
hcloud RDS ListInstances --cli-region={region} --limit=100 --offset=0 --cli-output=json
```

### Quality-reporting wrapper script (recommended)

```bash
python3 scripts/list_rds_instances.py --region={region} --names-only
python3 scripts/list_rds_instances.py --region={region} --type Ha --limit 20 --compact
```

The wrapper tries the CLI first, falls back to the `huaweicloudsdkrds` SDK, and
reports execution quality to the skillsopr console. Set `SKILL_QUALITY_DISABLE=1`
to disable reporting (local debugging).

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `--name` | No | Instance name filter (exact or `*fuzzy*` match) | `rds-prod` |
| `--id` | No | Instance ID filter (exact or `*fuzzy*` match) | `e229f7f2...in01` |
| `--type` | No | Instance type: `Single`/`Ha`/`Replica` | `Ha` |
| `--datastore_type` | No | Engine: `MySQL`/`PostgreSQL`/`SQLServer`/`MariaDB` | `MySQL` |
| `--vpc_id` | No | VPC ID filter | `81a7f347-...` |
| `--limit` | No | Max records per page (1–100, default 100) | `100` |
| `--offset` | No | Index offset (≥ 0, default 0) | `0` |
| `--names-only` | No | Print only the instance names (one per line) | `--names-only` |
| `--compact` | No | Print name/id/status/engine as TSV rows | `--compact` |

## KooCLI Command Format Standard

The KooCLI command format is:

`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]`

> Note: this is a generic format template, not an executable command — replace
> `<Service>`, `<Operation>`, `<region>` and the parameters with real values
> (e.g. `hcloud RDS ListInstances --cli-region=cn-north-4`).

- Service name: `RDS` (starts with uppercase).
- Operation name: PascalCase — `ListInstances`.
- Region: always pass `--cli-region=<region>`.
- Simple parameters use `--key=value`, for example `--name=rds-prod`.
- Pagination parameters: `--limit=N`, `--offset=N` (index offset).

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Least-privilege IAM permissions
- [CLI Installation Guide](references/cli-installation-guide.md) — hcloud CLI setup and authentication
- [Verification Method](references/verification-method.md) — How to verify the skill works
- [Dataflow Diagram](references/dataflow-diagram.md) — Request flow diagram
- [Acceptance Criteria](references/acceptance-criteria.md) — Acceptance test checklist
