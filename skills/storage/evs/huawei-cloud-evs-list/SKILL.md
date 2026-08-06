---
name: huawei-cloud-evs-list
description: |
  Query the list of Huawei Cloud EVS (Elastic Volume Service) disks under the
  current tenant / project, focused on the EVS disk NAME list. Returns each
  disk's name, id, status and size; can also output a pure EVS name-only list.
  Supports filtering by status, name and pagination (limit/offset). Uses the
  KooCLI command `hcloud EVS ListVolumes --cli-region={region}` (primary)
  against the v2 API, or the huaweicloudsdkevs Python SDK (fallback).
  Read-only — never creates, modifies or deletes any disk.
  Use this skill whenever the user wants to list/inspect the EVS disks of the
  tenant or query the EVS disk name list, e.g. for disk inventory, daily
  inspection, or cost review.
  Triggers include: "list EVS", "EVS list", "query EVS names", "EVS name
  list", "云硬盘列表", "查询云硬盘", "EVS磁盘名称", "云硬盘名称", "list volumes",
  "list elastic volumes", "how many EVS disks".
tags:
  - huawei-cloud
  - evs
  - list
  - storage
  - query
---

# Huawei Cloud EVS List Skill

## Overview

This skill queries the list of **EVS (Elastic Volume Service) disks** under the
current Huawei Cloud tenant / project and returns their key attributes — in
particular the **EVS disk name list** (`name`), along with `id`, `status` and
`size`. It is a read-only inspection skill: it never creates, modifies, or
deletes disks, snapshots, or any related resources.

**Architecture:**

```text
Agent → hcloud CLI (KooCLI, EVS ListVolumes, primary) → Huawei Cloud EVS v2 API
       ↘ huaweicloudsdkevs Python SDK (fallback)          ↗
```

**API path (verified from `huaweicloudsdkevs` v2 SDK `_list_volumes_http_info`):**

| Operation | Method | API Path |
|-----------|--------|----------|
| List EVS disks (detail) | GET | `/v2/{project_id}/cloudvolumes/detail` |

**Applicable Scenarios:**

- EVS disk inventory: "list all EVS disks of this tenant" or "show me the EVS disk name list"
- Daily inspection: snapshot of all disks with their status and size
- Cost review: enumerate disks to spot unused or oversized volumes
- Fast lookup: retrieve the exact EVS disk name(s) for follow-up operations

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询 EVS（云硬盘）列表**。不创建/删除/修改云硬盘，也不查询
> 快照、云硬盘详情（show-by-id）、挂载关系等其它资源。
> 若用户询问"创建/删除/扩容云硬盘"、"查询单个云硬盘详情"、"创建快照"等，
> 请明确告知本 Skill 不提供该能力。

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **Python 3.8+** with `huaweicloudsdkevs` package installed (SDK fallback only)
3. **IAM permissions** — `evs:volumes:list` (or the system policy `EVS ReadOnlyAccess`)
   is required to list EVS disks. See `references/iam-policies.md`
4. A region where the tenant owns EVS disks; specify it with `--cli-region`

## Workflow

1. **Identify the intent** — Confirm the user wants to list EVS disks (and
   optionally the filters: status, name, or name-only output).
2. **Confirm region** — Default `cn-north-4`; let the user override with another
   region if needed.
3. **Run the query** — Use the CLI command below with the requested filters.
4. **Present the results** — Show the disk name, id, status and size for each
   EVS disk; on a name-list request, output just the names.
5. **Handle errors** — If the CLI fails (credentials/permissions/network), retry
   with the SDK fallback described in `references/verification-method.md`.
6. **Handle empty results** — If a filtered query returns an empty list
   (`count: 0`), **first verify that the filter value is legal** — in
   particular the `status` value must be one of the enum values listed below.
   The EVS API silently ignores an invalid `status` value and returns an empty
   list with HTTP 200 (no error), so an illegal filter value is
   indistinguishable from "no disks of that status" unless checked. Confirm the
   filter is valid before reporting "no matching disks" to the user.

## Core Commands

> KooCLI format: `hcloud <Service> <Operation> --cli-region=<region> [--key=value]`

### List all EVS disks (names, ids, status, size)

```bash
hcloud EVS ListVolumes --cli-region={region} --cli-output=json
```

### List only the EVS disk names

```bash
hcloud EVS ListVolumes --cli-region={region} --cli-output=json | jq -r '.volumes[].name'
```

### Compact fields: name, id, status, size

```bash
hcloud EVS ListVolumes --cli-region={region} --cli-output=json \
  | jq -r '.volumes[] | [.name, .id, .status, .size] | @tsv'
```

### Filter by disk status

```bash
hcloud EVS ListVolumes --cli-region={region} --status=available --cli-output=json
```

> **`status` accepts enum values ONLY.** The valid values are:
> `creating`, `available`, `reserved`, `attaching`, `in-use`,
> `deleting`, `error`, `error_deleting`, `backing-up`, `restoring-backup`,
> `extending`, `downloading`, `uploading`, `retyping`, `rollbacking`.
>
> **Invalid values are silently ignored by the EVS API** — a typo such as
> `--status=avaliable` (or any value outside the enum above) returns HTTP 200
> with an empty list (`{"count":0,"volumes":[]}`) and exit code 0, with **no
> error message**. This is indistinguishable from "the project has no disks of
> that status". Always use the exact enum values above, and when a status
> filter returns an empty result, double-check that the value used is a valid
> enum value before concluding that no disks match.

### Filter by disk name

```bash
hcloud EVS ListVolumes --cli-region={region} --name={volume_name} --cli-output=json
```

### Pagination (limit / offset)

```bash
hcloud EVS ListVolumes --cli-region={region} --limit=25 --offset=0 --cli-output=json
```

> **Note:** In the EVS v2 list response, the disk **name** is the top-level
> `name` field of each item in `volumes[]`. The **id** is `id`, the **status**
> is `status` and the **size** (GB) is `size`. `count` holds the total number of
> matched disks. `offset` is a record offset (0-based) used together with
> `limit`; the default limit is 1000.

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `{status}` | No | Disk status filter — enum only: `creating`, `available`, `in-use`, `error`, etc. (invalid values silently return an empty list) | `available` |
| `{name}` | No | Disk name filter | `data-disk-01` |
| `{limit}` | No | Max records returned (default 1000) | `25` |
| `{offset}` | No | Record offset, 0-based (default 0) | `0` |

## KooCLI Command Format Standard

The KooCLI command format is:

`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]`

> Note: this is a generic format template, not an executable command — replace
> `<Service>`, `<Operation>`, `<region>` and the parameters with real values
> (e.g. `hcloud EVS ListVolumes --cli-region=cn-north-4`).

- Service name: `EVS` (starts with uppercase).
- Operation name: PascalCase — `ListVolumes`.
- Region: always pass `--cli-region=<region>`.
- Simple parameters use `--key=value`, for example `--status=available`.

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Least-privilege IAM permissions
- [CLI Installation Guide](references/cli-installation-guide.md) — hcloud CLI setup and authentication
- [Verification Method](references/verification-method.md) — How to verify the skill works
- [Dataflow Diagram](references/dataflow-diagram.md) — Request flow diagram
- [Acceptance Criteria](references/acceptance-criteria.md) — Acceptance test checklist
