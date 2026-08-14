---
name: huawei-cloud-sfsturbo-list
description: |
  Query the list of Huawei Cloud SFS (Scalable File Service, 弹性文件服务 /
  SFS Turbo) file systems under the current tenant / project, focused on the
  SFS NAME list. Returns each file system's name, id, status, size, protocol
  and region; can also output a pure SFS name-only list.
  Supports pagination (limit/offset). Uses the KooCLI command
  `hcloud SFSTurbo ListShares --cli-region={region}` (primary) against the
  v1 API, or the huaweicloudsdksfsturbo Python SDK (fallback).
  Read-only — never creates, modifies or deletes any file system.
  Use this skill whenever the user wants to list/inspect the SFS file systems
  of the tenant or query the SFS name list, e.g. for storage inventory, daily
  inspection, or cost review.
  Triggers include: "list SFS", "SFS list", "query SFS names", "SFS name
  list", "弹性文件服务列表", "查询SFS", "SFS名称", "sfs 列表", "list shares",
  "list file systems", "how many SFS", "SFS Turbo 列表".
tags:
  - huawei-cloud
  - sfsturbo
  - list
  - storage
  - query
---

# Huawei Cloud SFS (SFSTurbo) List Skill

## Overview

This skill queries the list of **SFS (Scalable File Service / 弹性文件服务,
SFS Turbo) file systems** under the current Huawei Cloud tenant / project and
returns their key attributes — in particular the **SFS name list** (`name`),
along with `id`, `status`, `size`, `share_proto` and `region`. It is a
read-only inspection skill: it never creates, modifies, or deletes file
systems, or any related resources.

**Architecture:**

```text
Agent → hcloud CLI (KooCLI, SFSTurbo ListShares, primary) → Huawei Cloud SFS v1 API
       ↘ huaweicloudsdksfsturbo Python SDK (fallback)      ↗
```

**API path (verified from `huaweicloudsdksfsturbo` v1 SDK `_list_shares_http_info`):**

| Operation | Method | API Path |
|-----------|--------|----------|
| List SFS file systems (detail) | GET | `/v1/{project_id}/sfs-turbo/shares/detail` |

**Execution-quality reporting:** every invocation of
`scripts/list_sfsturbo_shares.py` reports a trace_id, status
(`success` / `biz_fail` / `sys_fail`), error code and cost to the skillsopr
operations console via the vendored `scripts/skill_quality_sdk.py`. Reporting
is non-blocking and fails silently; it never affects the query result.

**Applicable Scenarios:**

- SFS inventory: "list all SFS file systems of this tenant" or "show me the SFS name list"
- Daily inspection: snapshot of all file systems with their status and size
- Cost review: enumerate file systems to spot unused or oversized storage
- Fast lookup: retrieve the exact SFS name(s) for follow-up operations

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询 SFS（弹性文件服务 / SFS Turbo）文件系统列表**。
> 不创建/删除/修改/扩容文件系统，也不查询单个文件系统详情（show-by-id）、
> 挂载目标、权限规则、数据转储等其它资源。
> 若用户询问"创建/删除/扩容文件系统"、"查询单个文件系统详情"、"查询挂载
> 目标"等，请明确告知本 Skill 不提供该能力。

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **Python 3.8+** with `huaweicloudsdksfsturbo` package installed (SDK fallback only)
3. **IAM permissions** — `sfsturbo:shares:listShares` (or the system policy
   `SFS Turbo ReadOnlyAccess`) is required to list SFS file systems. See `references/iam-policies.md`
4. A region where the tenant owns SFS file systems; specify it with `--cli-region`

## Workflow

1. **Identify the intent** — Confirm the user wants to list SFS file systems
   and whether they need only the **name list** (`--names-only`) or the full
   attributes (name, id, status, size, share_proto, region).
2. **Confirm region** — Default `cn-north-4`; let the user override with another
   region if needed.
3. **Run the query** — Use the CLI command below with the requested filters.
4. **Present the results** — Show the name list, or name/id/status/size per
   file system; on a name-list request, output just the names.
5. **Handle errors** — If the CLI fails (credentials/permissions/network), retry
   with the SDK fallback described in `references/verification-method.md`.
6. **Handle empty results** — A tenant may legitimately have zero SFS file
   systems in a region (`shares: []` with HTTP 200). Report "no SFS file
   systems found in region X" instead of an error.

## Core Commands

> KooCLI format: `hcloud <Service> <Operation> --cli-region=<region> [--key=value]`

### List all SFS file systems

```bash
hcloud SFSTurbo ListShares --cli-region={region} --cli-output=json
```

### Wrapper script (recommended — includes quality reporting)

A Python wrapper is provided at `scripts/list_sfsturbo_shares.py`. It runs the
CLI command (or the SDK fallback), prints results as JSON lines or a pure name
list, and reports execution quality to the skillsopr operations console via
the vendored `scripts/skill_quality_sdk.py`. Set `SKILL_QUALITY_DISABLE=1` to
disable reporting (local debugging).

```bash
# List SFS file system names (one per line) — the "name list" use case
python3 scripts/list_sfsturbo_shares.py --names-only

# List SFS file systems with attributes (name, id, status, size, ...)
python3 scripts/list_sfsturbo_shares.py

# Paginated query
python3 scripts/list_sfsturbo_shares.py --limit 20 --offset 0

# Force SDK executor (fallback path)
python3 scripts/list_sfsturbo_shares.py --executor sdk
```

### List only the SFS names (name-only list)

```bash
hcloud SFSTurbo ListShares --cli-region={region} --cli-output=json | jq -r '.shares[].name'
```

### Compact fields: name, id, status, size

```bash
hcloud SFSTurbo ListShares --cli-region={region} --cli-output=json \
  | jq -r '.shares[] | [.name, .id, .status, .size] | @tsv'
```

### Pagination (limit / offset)

```bash
hcloud SFSTurbo ListShares --cli-region={region} --limit=10 --offset=0 --cli-output=json
```

> **Note:** In the SFS v1 list response `ListShares` returns `shares[]`; each
> item's name is the **`name`** field, `id` is the file system id, `status` is
> the file system status (e.g. `100` = available, `200` = creating), `size` is
> the capacity in GB, `share_proto` is the protocol (`NFS` / `SMB`), and
> `region` is the region where the file system resides. `limit` default is
> 1000 (range 1–1000); `offset` is the pagination offset (default 0).

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `{limit}` | No | Max records returned (default 1000, max 1000) | `50` |
| `{offset}` | No | Record offset (default 0) | `0` |
| `{names_only}` | No | Print only SFS names, one per line | `--names-only` |

## KooCLI Command Format Standard

The KooCLI command format is:

`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]`

> Note: this is a generic format template, not an executable command — replace
> `<Service>`, `<Operation>`, `<region>` and the parameters with real values
> (e.g. `hcloud SFSTurbo ListShares --cli-region=cn-north-4`).

- Service name: `SFSTurbo` (starts with uppercase).
- Operation name: PascalCase — `ListShares`.
- Region: always pass `--cli-region=<region>`.
- Simple parameters use `--key=value`, for example `--limit=50`.

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Least-privilege IAM permissions
- [CLI Installation Guide](references/cli-installation-guide.md) — hcloud CLI setup and authentication
- [Verification Method](references/verification-method.md) — How to verify the skill works
- [Dataflow Diagram](references/dataflow-diagram.md) — Request flow diagram
- [Acceptance Criteria](references/acceptance-criteria.md) — Acceptance test checklist
