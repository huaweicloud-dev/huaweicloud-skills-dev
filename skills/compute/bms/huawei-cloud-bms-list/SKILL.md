---
name: huawei-cloud-bms-list
description: |
  Query the list of Huawei Cloud BMS (Bare Metal Server) instances under the
  current tenant / project, focused on the BMS NAME list. Returns each
  server's name, id and status; can also output a pure BMS name-only list.
  Supports filtering by status, name and pagination (limit/offset). Uses the
  KooCLI command `hcloud BMS ListBareMetalServers --cli-region={region}`
  (primary) against the v1 API, or the huaweicloudsdkbms Python SDK (fallback).
  Read-only — never creates, modifies or deletes any bare metal server.
  Use this skill whenever the user wants to list/inspect the BMS instances of
  the tenant or query the BMS name list, e.g. for BMS inventory, daily
  inspection, or cost review.
  Triggers include: "list BMS", "BMS list", "query BMS names", "BMS name
  list", "裸金属服务器列表", "查询裸金属服务器", "BMS名称列表", "裸金属服务器名称",
  "list bare metal servers", "how many BMS".
tags:
  - huawei-cloud
  - bms
  - list
  - bare-metal
  - query
---

# Huawei Cloud BMS List Skill

## Overview

This skill queries the list of **BMS (Bare Metal Server) instances** under the
current Huawei Cloud tenant / project and returns their key attributes — in
particular the **BMS name list** (`name`), along with `id` and `status`. It is
a read-only inspection skill: it never creates, modifies, or deletes servers,
volumes, NICs, or any related resources.

**Architecture:**

```text
Agent → hcloud CLI (KooCLI, BMS ListBareMetalServers, primary) → Huawei Cloud BMS v1 API
       ↘ huaweicloudsdkbms Python SDK (fallback)                ↗
```

**API path (verified from `huaweicloudsdkbms` v1 SDK `_list_bare_metal_servers_http_info`):**

| Operation | Method | API Path |
|-----------|--------|----------|
| List bare metal servers | GET | `/v1/{project_id}/baremetalservers/detail` |

**Applicable Scenarios:**

- BMS inventory: "list all BMS instances of this tenant" or "show me the BMS name list"
- Daily inspection: snapshot of all bare metal servers with their status
- Cost review: enumerate servers to spot unused or oversized resources
- Fast lookup: retrieve the exact BMS name(s) for follow-up operations

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询 BMS（裸金属服务器）列表**。不创建/删除/修改裸金属服务器，
> 也不查询/操作单台服务器的详情（show-by-id）、网卡、磁盘、密码等其它资源。
> 若用户询问"创建/删除/重启裸金属服务器"、"查询单台服务器详情"、"挂载磁盘"等，
> 请明确告知本 Skill 不提供该能力。

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **Python 3.8+** with `huaweicloudsdkbms` package installed (SDK fallback only)
3. **IAM permissions** — `bms:servers:list` (or the system policy `BMS ReadOnlyAccess`)
   is required to list bare metal servers. See `references/iam-policies.md`
4. A region where the tenant owns BMS instances; specify it with `--cli-region`

## Workflow

1. **Identify the intent** — Confirm the user wants to list BMS instances (and
   optionally the filters: status, name, or name-only output).
2. **Confirm region** — Default `cn-north-4`; let the user override with another
   region if needed.
3. **Run the query** — Use the CLI command below with the requested filters.
4. **Present the results** — Show the server name, id and status for each BMS;
   on a name-list request, output just the names.
5. **Handle errors** — If the CLI fails (credentials/permissions/network), retry
   with the SDK fallback described in `references/verification-method.md`.

## Core Commands

> KooCLI format: `hcloud <Service> <Operation> --cli-region=<region> [--key=value]`

### List all BMS instances (names, ids, status)

```bash
hcloud BMS ListBareMetalServers --cli-region={region} --cli-output=json
```

### List only the BMS names

```bash
hcloud BMS ListBareMetalServers --cli-region={region} --cli-output=json | jq -r '.servers[].name'
```

### Compact fields: name, id, status

```bash
hcloud BMS ListBareMetalServers --cli-region={region} --cli-output=json \
  | jq -r '.servers[] | [.name, .id, .status] | @tsv'
```

### Filter by BMS status

```bash
hcloud BMS ListBareMetalServers --cli-region={region} --status=ACTIVE --cli-output=json
```

Status enum: `ACTIVE`, `BUILD`, `ERROR`, `HARD_REBOOT`, `REBOOT`, `REBUILD`,
`SHUTOFF`.

> **Note:** Invalid status values are **silently ignored** by the BMS API — the
> request still returns HTTP 200 with an unfiltered server list. Always use the
> exact enum values listed above; a typo will not raise an error and the
> returned list will not be filtered as expected.

### Filter by BMS name

```bash
hcloud BMS ListBareMetalServers --cli-region={region} --name={server_name} --cli-output=json
```

### Pagination (limit / offset)

```bash
hcloud BMS ListBareMetalServers --cli-region={region} --limit=25 --offset=1 --cli-output=json
```

> **Note:** In the BMS v1 list response, the server **name** is the top-level
> `name` field of each item in `servers[]`. The **id** is `id` and the
> **status** is `status`. `count` holds the total number of matched servers.

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `{status}` | No | Server status filter | `ACTIVE` |
| `{name}` | No | Server name filter | `bms-01` |
| `{limit}` | No | Page size (default 25, max 1000) | `25` |
| `{offset}` | No | Page number (starts at 1) | `1` |

## KooCLI Command Format Standard

The KooCLI command format is:

`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]`

> Note: this is a generic format template, not an executable command — replace
> `<Service>`, `<Operation>`, `<region>` and the parameters with real values
> (e.g. `hcloud BMS ListBareMetalServers --cli-region=cn-north-4`).

- Service name: `BMS` (starts with uppercase).
- Operation name: PascalCase — `ListBareMetalServers`.
- Region: always pass `--cli-region=<region>`.
- Simple parameters use `--key=value`, for example `--status=ACTIVE`.

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Least-privilege IAM permissions
- [CLI Installation Guide](references/cli-installation-guide.md) — hcloud CLI setup and authentication
- [Verification Method](references/verification-method.md) — How to verify the skill works
- [Dataflow Diagram](references/dataflow-diagram.md) — Request flow diagram
- [Acceptance Criteria](references/acceptance-criteria.md) — Acceptance test checklist
