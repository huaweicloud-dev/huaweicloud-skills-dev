---
name: huawei-cloud-vpcep-list
description: |
  Query the list of Huawei Cloud VPCEP (VPC Endpoint / VPC Endpoint Service)
  resources under the current tenant / project, focused on the VPCEP NAME
  list. Returns each VPC endpoint's name (endpoint_service_name), id, status
  and service type, and each endpoint service's name (service_name), id and
  status. Supports filtering by endpoint service name and pagination
  (limit/offset). Uses the KooCLI commands `hcloud VPCEP ListEndpoints` and
  `hcloud VPCEP ListEndpointService --cli-region={region}` (primary) against
  the v1 API, or the huaweicloudsdkvpcep Python SDK (fallback).
  Read-only — never creates, modifies or deletes any endpoint or service.
  Use this skill whenever the user wants to list/inspect the VPCEP endpoints
  or endpoint services of the tenant or query the VPCEP name list, e.g. for
  endpoint inventory, daily inspection, or connectivity review.
  Triggers include: "list VPCEP", "VPCEP list", "query VPCEP names", "VPCEP
  name list", "终端节点列表", "查询终端节点", "VPCEP名称", "终端节点名称", "list
  endpoints", "list endpoint services", "how many VPCEP endpoints".
tags:
  - huawei-cloud
  - vpcep
  - list
  - network
  - query
---

# Huawei Cloud VPCEP List Skill

## Overview

This skill queries the list of **VPCEP (VPC Endpoint / VPC Endpoint Service)**
resources under the current Huawei Cloud tenant / project and returns their key
attributes — in particular the **VPCEP name list**, along with `id`, `status`
and `service_type`. It is a read-only inspection skill: it never creates,
modifies, or deletes endpoints, endpoint services, or any related resources.

VPCEP contains two resource types, both covered by this skill:

1. **VPC Endpoints** (终端节点) — private connections from your VPC to
   endpoint services; listed with `hcloud VPCEP ListEndpoints`. Each endpoint's
   display name is the `endpoint_service_name` field.
2. **VPC Endpoint Services** (终端节点服务) — services published for others to
   connect to; listed with `hcloud VPCEP ListEndpointService`. Each service's
   name is the `service_name` field.

**Architecture:**

```text
Agent → hcloud CLI (KooCLI, VPCEP ListEndpoints / ListEndpointService, primary)
        → Huawei Cloud VPCEP v1 API
       ↘ huaweicloudsdkvpcep Python SDK (fallback)
```

**API paths (verified from `huaweicloudsdkvpcep` v1 SDK `_http_info`):**

| Operation | Method | API Path |
|-----------|--------|----------|
| List VPC endpoints | GET | `/v1/{project_id}/vpc-endpoints` |
| List VPC endpoint services | GET | `/v1/{project_id}/vpc-endpoint-services` |

**Applicable Scenarios:**

- VPCEP inventory: "list all VPCEP endpoints / endpoint services of this tenant"
- Daily inspection: snapshot of all endpoints with their status
- Connectivity review: enumerate endpoints to check which services they connect to
- Fast lookup: retrieve the exact endpoint / service names for follow-up operations

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询 VPCEP（终端节点 / 终端节点服务）列表**。不创建/删除/修改
> 终端节点或终端节点服务，也不查询单个资源详情（show-by-id）、连接审批、
> 权限管理等其它能力。
> 若用户询问"创建/删除终端节点"、"查询单个终端节点详情"、"审批连接"等，
> 请明确告知本 Skill 不提供该能力。

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **Python 3.8+** with `huaweicloudsdkvpcep` package installed (SDK fallback only)
3. **IAM permissions** — `vpcep:endpoints:list` and `vpcep:endpointServices:list`
   (or the system policy `VPCEndpoint ReadOnlyAccess`) are required to list
   VPCEP resources. See `references/iam-policies.md`
4. A region where the tenant owns VPCEP resources; specify it with `--cli-region`

## Workflow

1. **Identify the intent** — Confirm whether the user wants VPC **endpoints**
   (`ListEndpoints`), **endpoint services** (`ListEndpointService`), or both.
   The default is endpoints.
2. **Confirm region** — Default `cn-north-4`; let the user override with another
   region if needed.
3. **Run the query** — Use the CLI command below with the requested filters.
4. **Present the results** — Show the name (endpoint_service_name /
   service_name), id, status and service type for each resource; on a
   name-list request, output just the names.
5. **Handle errors** — If the CLI fails (credentials/permissions/network), retry
   with the SDK fallback described in `references/verification-method.md`.
6. **Handle empty results** — A filtered query may legitimately return an empty
   list (`endpoints: []` / `endpoint_services: []` with HTTP 200). Verify the
   filter value is legal before reporting "no matching resources" to the user.

## Core Commands

> KooCLI format: `hcloud <Service> <Operation> --cli-region=<region> [--key=value]`

### List all VPC endpoints

```bash
hcloud VPCEP ListEndpoints --cli-region={region} --cli-output=json
```

### Wrapper script (recommended — includes quality reporting)

A Python wrapper is provided at `scripts/list_vpcep.py`. It runs the CLI
commands (or the SDK fallback), prints results as JSON lines, and reports
execution quality to the skillsopr operations console via the vendored
`scripts/skill_quality_sdk.py`. Set `SKILL_QUALITY_DISABLE=1` to disable
reporting (local debugging).

```bash
# List endpoint names (one per line)
python3 scripts/list_vpcep.py --names-only

# List endpoint services (names + ids + status)
python3 scripts/list_vpcep.py --resource-type services

# Filter by endpoint service name, paginated
python3 scripts/list_vpcep.py --resource-type endpoints --name my-service --limit 20 --offset 0

# Force SDK executor (fallback path)
python3 scripts/list_vpcep.py --resource-type endpoints --executor sdk
```

> **Project scoping note:** the hcloud CLI resolves the account **default**
> project for the region, while the SDK region default may differ. If the SDK
> path returns an empty list while the CLI shows resources, pass
> `--project-id <id>` to align the SDK scope (the id is visible in the CLI
> output's `project_id` field).

### List only the VPC endpoint names (endpoint_service_name)

```bash
hcloud VPCEP ListEndpoints --cli-region={region} --cli-output=json | jq -r '.endpoints[].endpoint_service_name'
```

### Compact fields: name, id, status, service_type

```bash
hcloud VPCEP ListEndpoints --cli-region={region} --cli-output=json \
  | jq -r '.endpoints[] | [.endpoint_service_name, .id, .status, .service_type] | @tsv'
```

### Filter endpoints by endpoint service name

```bash
hcloud VPCEP ListEndpoints --cli-region={region} --endpoint_service_name={name} --cli-output=json
```

### Filter endpoints by VPC id

```bash
hcloud VPCEP ListEndpoints --cli-region={region} --vpc_id={vpc_id} --cli-output=json
```

### Pagination (limit / offset)

```bash
hcloud VPCEP ListEndpoints --cli-region={region} --limit=10 --offset=0 --cli-output=json
```

### List all VPC endpoint services

```bash
hcloud VPCEP ListEndpointService --cli-region={region} --cli-output=json
```

### List only the endpoint service names (service_name)

```bash
hcloud VPCEP ListEndpointService --cli-region={region} --cli-output=json | jq -r '.endpoint_services[].service_name'
```

### Filter endpoint services by name

```bash
hcloud VPCEP ListEndpointService --cli-region={region} --endpoint_service_name={name} --cli-output=json
```

### Filter endpoint services by status

```bash
hcloud VPCEP ListEndpointService --cli-region={region} --status={status} --cli-output=json
```

> **Note:** In the VPCEP v1 list responses:
>
> - `ListEndpoints` returns `endpoints[]`; each item's display name is the
>   **`endpoint_service_name`** field (the endpoint itself has no separate
>   `name` field). `id` is the endpoint id, `status` is the endpoint status
>   (e.g. `accepted`), `service_type` is `interface` or `gateway`.
> - `ListEndpointService` returns `endpoint_services[]`; each item's name is
>   the **`service_name`** field, `id` is the service id, `status` is the
>   service status (e.g. `available`).
> - `limit` default is 10 (range 0–500); `offset` must be an integer greater
>   than 0. Use `--limit=500` to fetch more records per page.

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `{resource_type}` | No | `endpoints` (default) or `services` | `endpoints` |
| `{endpoint_service_name}` | No | Endpoint service name filter (fuzzy match, case-insensitive) | `my-service` |
| `{id}` | No | Unique resource id filter | `df39acea-3538-4c31-86c3-682192de9c50` |
| `{vpc_id}` | No | VPC id filter (endpoints only) | `e5331bb4-c4af-4667-aabc-46593ffead50` |
| `{status}` | No | Status filter (services only) | `available` |
| `{limit}` | No | Max records returned (default 10, max 500) | `50` |
| `{offset}` | No | Record offset (must be > 0) | `0` |

## KooCLI Command Format Standard

The KooCLI command format is:

`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]`

> Note: this is a generic format template, not an executable command — replace
> `<Service>`, `<Operation>`, `<region>` and the parameters with real values
> (e.g. `hcloud VPCEP ListEndpoints --cli-region=cn-north-4`).

- Service name: `VPCEP` (starts with uppercase).
- Operation name: PascalCase — `ListEndpoints`, `ListEndpointService`.
- Region: always pass `--cli-region=<region>`.
- Simple parameters use `--key=value`, for example `--limit=50`.

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Least-privilege IAM permissions
- [CLI Installation Guide](references/cli-installation-guide.md) — hcloud CLI setup and authentication
- [Verification Method](references/verification-method.md) — How to verify the skill works
- [Dataflow Diagram](references/dataflow-diagram.md) — Request flow diagram
- [Acceptance Criteria](references/acceptance-criteria.md) — Acceptance test checklist
