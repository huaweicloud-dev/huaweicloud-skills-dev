---
name: huawei-cloud-dds-list
description: |
  Query the list of Huawei Cloud DDS (Document Database Service, 文档数据库服务)
  instances under the current tenant / project and return the DDS instance
  NAMES. By default the skill prints only the instance names (one per line);
  with extra flags it also returns id, status, mode, datastore engine,
  version and created time. Supports filtering by instance name, id, mode
  (Sharding/ReplicaSet/Single), datastore type (DDS-Community/DDS-Enhanced),
  VPC and subnet, plus pagination via limit/offset. Uses the KooCLI command
  `hcloud DDS ListInstances --cli-region={region}` (primary) or the
  huaweicloudsdkdds Python SDK (fallback). Read-only — never creates,
  modifies, deletes, restarts or stops any DDS instance.
  Use this skill whenever the user wants to list/inspect the DDS instances of
  the tenant or query the DDS instance name list, e.g. for database inventory,
  daily inspection, or cost review.
  Triggers include: "list DDS", "DDS list", "query DDS names", "DDS实例列表",
  "查询DDS", "DDS实例名称", "dds list", "how many DDS", "DDS inventory",
  "list document database instances", "文档数据库实例", "MongoDB实例列表".
tags:
  - huawei-cloud
  - dds
  - database
  - list
  - query
---

# Huawei Cloud DDS List Skill

## Overview

This skill queries the list of **Document Database Service (文档数据库服务
DDS)** instances under the current Huawei Cloud tenant / project and returns
their key attributes — by default only the **DDS instance names** (`name`,
one per line), optionally together with `id`, `status`, `mode`, `datastore`
engine, `version`, `vpc_id` and `created` time. It is a read-only inspection
skill: it never creates, modifies, deletes, restarts or stops any database
instance.

**Architecture:**

```text
Agent → hcloud CLI (KooCLI, DDS ListInstances, primary) → Huawei Cloud DDS v3 API
       ↘ huaweicloudsdkdds Python SDK (fallback)                  ↗
```

**API path (verified from `huaweicloudsdkdds` v3 SDK `_list_instances_http_info`):**

| Operation | Method | API Path |
|-----------|--------|----------|
| List DDS instances | GET | `/v3/{project_id}/instances` |

**Execution-quality reporting:** every invocation of
`scripts/list_dds_instances.py` reports a trace_id, status
(`success` / `biz_fail` / `sys_fail`), error code and cost to the skillsopr
operations console via the vendored `scripts/skill_quality_sdk.py`. Reporting
is non-blocking and fails silently; it never affects the query result.

**Applicable Scenarios:**

- Database inventory: "list all DDS instances of this tenant" or "show me the DDS name list"
- Daily inspection: snapshot of all DDS instances with their status and engine
- Cost review: enumerate DDS instances and their modes to spot unused or oversized databases
- Fast lookup: retrieve the exact DDS instance name/id for follow-up operations
- Auto detection: periodic checks that detect new/stopped/error DDS instances

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询 DDS 实例列表**。不创建/删除/修改/重启/停止 DDS 实例，
> 也不查询备份、参数组、日志等其它 DDS 资源。
> 若用户询问"创建/删除 DDS"、"重启 DDS"、"查询备份"等，
> 请明确告知本 Skill 不提供该能力。

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **Python 3.8+** with `huaweicloudsdkdds` package installed (SDK fallback only)
3. **IAM permissions** — `dds:instance:list` (or the system policy
   `DDS ReadOnlyAccess`) is required to list DDS instances. See `references/iam-policies.md`
4. A region where the tenant owns DDS instances; specify it with `--cli-region`

## Workflow

1. **Identify the intent** — Confirm the user wants to list DDS instances
   (and optionally the filters: name, id, mode, datastore type, or name-only output).
2. **Confirm region** — Default `cn-north-4`; let the user override with another
   region if needed.
3. **Run the query** — Use the CLI command below with the requested filters.
4. **Present the results** — By default output only the DDS instance names
   (one per line); with `--compact` or full JSON output show the extra fields.
5. **Handle errors** — If the CLI fails (credentials/permissions/network), retry
   with the SDK fallback described in `references/verification-method.md`.

## Core Commands

> KooCLI format: `hcloud <Service> <Operation> --cli-region=<region> [--key=value]`

### List all DDS instances (full JSON)

```bash
hcloud DDS ListInstances --cli-region={region} --cli-output=json
```

### List only the DDS instance names

```bash
hcloud DDS ListInstances --cli-region={region} --cli-query="instances[].name"
```

### Compact fields: name, id, status, mode

```bash
hcloud DDS ListInstances --cli-region={region} --cli-output=json \
  | jq -r '.instances[] | [.name, .id, .status, .mode] | @tsv'
```

### Filter by datastore type / mode / name / VPC / subnet

```bash
hcloud DDS ListInstances --cli-region={region} --datastore_type=DDS-Community --cli-output=json
hcloud DDS ListInstances --cli-region={region} --cli-mode=AKSK --mode=ReplicaSet --cli-output=json
hcloud DDS ListInstances --cli-region={region} --name={instance-name} --cli-output=json
hcloud DDS ListInstances --cli-region={region} --name='*{name-prefix}' --cli-output=json
hcloud DDS ListInstances --cli-region={region} --vpc_id={vpc-id} --cli-output=json
hcloud DDS ListInstances --cli-region={region} --subnet_id={subnet-id} --cli-output=json
```

> Note: the DDS API `--name` filter supports **exact match** or **`*prefix`
> fuzzy match** (`*` is a reserved prefix character — `--name='*prod'` matches
> names starting with "prod"). `*` cannot appear in the middle or at the end
> (`--name='*prod*'` fails with `DBS.200021`). The `--id` filter is
> **exact match only** — no fuzzy wildcards. `--mode` is both a KooCLI system
> parameter (auth mode) and a DDS API filter parameter; pin the system
> parameter explicitly with `--cli-mode=AKSK` so `--mode=ReplicaSet` is passed
> to the DDS API (otherwise KooCLI prompts interactively or fails with
> `[USE_ERROR]`). The wrapper script `scripts/list_dds_instances.py` handles
> all of these automatically.

### Pagination

```bash
hcloud DDS ListInstances --cli-region={region} --limit=100 --offset=0 --cli-output=json
```

### Quality-reporting wrapper script (recommended)

```bash
python3 scripts/list_dds_instances.py --region={region} --names-only
python3 scripts/list_dds_instances.py --region={region} --mode ReplicaSet --limit 20 --compact
```

The wrapper tries the CLI first, falls back to the `huaweicloudsdkdds` SDK, and
reports execution quality to the skillsopr console. Set `SKILL_QUALITY_DISABLE=1`
to disable reporting (local debugging).

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `--name` | No | Instance name filter: exact match, or `*prefix` fuzzy match (`*` is a reserved prefix char) | `dds-prod` / `*prod` |
| `--id` | No | Instance ID filter (exact match only) | `ec636f26...in02` |
| `--mode` | No | Instance mode: `Sharding`/`ReplicaSet`/`Single` | `ReplicaSet` |
| `--datastore_type` | No | Database type: `DDS-Community`/`DDS-Enhanced` | `DDS-Community` |
| `--vpc_id` | No | VPC ID filter | `0b4171c1-...` |
| `--subnet_id` | No | Subnet ID filter | `fa5fb1a9-...` |
| `--limit` | No | Max records per page (1–100, default 100) | `100` |
| `--offset` | No | Index offset (≥ 0, default 0) | `0` |
| `--names-only` | No | Print only the instance names (one per line) | `--names-only` |
| `--compact` | No | Print name/id/status/mode as TSV rows | `--compact` |

## KooCLI Command Format Standard

The KooCLI command format is:

`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]`

> Note: this is a generic format template, not an executable command — replace
> `<Service>`, `<Operation>`, `<region>` and the parameters with real values
> (e.g. `hcloud DDS ListInstances --cli-region=cn-north-4`).

- Service name: `DDS` (starts with uppercase).
- Operation name: PascalCase — `ListInstances`.
- Region: always pass `--cli-region=<region>`.
- Simple parameters use `--key=value`, for example `--name=dds-prod`.
- Pagination parameters: `--limit=N`, `--offset=N` (index offset).

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Least-privilege IAM permissions
- [CLI Installation Guide](references/cli-installation-guide.md) — hcloud CLI setup and authentication
- [Verification Method](references/verification-method.md) — How to verify the skill works
- [Dataflow Diagram](references/dataflow-diagram.md) — Request flow diagram
- [Acceptance Criteria](references/acceptance-criteria.md) — Acceptance test checklist
