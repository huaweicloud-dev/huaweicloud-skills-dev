---
name: huawei-cloud-nat-list
description: |
  Query the list of Huawei Cloud public NAT gateways (公网NAT网关) under the
  current tenant / project, focused on the NAT gateway NAME list. Returns each
  gateway's name, id, status, spec, router (VPC) id, internal network id and
  created time. Supports filtering by name, id, status, spec, enterprise
  project id and pagination via limit/marker. Uses the KooCLI command
  `hcloud NAT ListNatGateways --cli-region={region}` (primary) against the v2
  API, or the huaweicloudsdknat Python SDK (fallback). Read-only — never
  creates, modifies or deletes any NAT gateway.
  Use this skill whenever the user wants to list/inspect the public NAT
  gateways of the tenant or query the NAT gateway name list, e.g. for NAT
  gateway inventory, daily inspection, or cost review.
  Triggers include: "list NAT gateways", "NAT gateway list", "query NAT
  gateway names", "公网NAT网关列表", "查询公网NAT网关", "NAT网关列表", "NAT网关名称",
  "list nat", "nat list", "how many NAT gateways", "NAT inventory".
tags:
  - huawei-cloud
  - nat
  - network
  - list
  - query
---

# Huawei Cloud Public NAT Gateway List Skill

## Overview

This skill queries the list of **public NAT gateways (公网NAT网关)** under the
current Huawei Cloud tenant / project and returns their key attributes — in
particular the **NAT gateway name list** (`name`), along with `id`, `status`,
`spec`, `router_id` (VPC id), `internal_network_id` and `created_at`. It is a
read-only inspection skill: it never creates, modifies, or deletes NAT
gateways or any related resources (SNAT/DNAT rules, transit IPs).

**Architecture:**

```text
Agent → hcloud CLI (KooCLI, NAT ListNatGateways, primary) → Huawei Cloud NAT v2 API
       ↘ huaweicloudsdknat Python SDK (fallback)              ↗
```

**API path (verified from `huaweicloudsdknat` v2 SDK `_list_nat_gateways_http_info`):**

| Operation | Method | API Path |
|-----------|--------|----------|
| List NAT gateways | GET | `/v2/{project_id}/nat_gateways` |
| Show NAT gateway | GET | `/v2/{project_id}/nat_gateways/{nat_gateway_id}` |
| List NAT gateway specs | GET | `/v2/{project_id}/nat_gateway_specs` |

**Execution-quality reporting:** every invocation of
`scripts/list_nat_gateways.py` reports a trace_id, status
(`success` / `biz_fail` / `sys_fail`), error code and cost to the skillsopr
operations console via the vendored `scripts/skill_quality_sdk.py`. Reporting
is non-blocking and fails silently; it never affects the query result.

**Applicable Scenarios:**

- NAT gateway inventory: "list all public NAT gateways of this tenant" or "show me the NAT gateway name list"
- Daily inspection: snapshot of all NAT gateways with their status and spec
- Cost review: enumerate NAT gateways and their specs to spot unused or oversized resources
- Fast lookup: retrieve the exact NAT gateway name/id for follow-up operations

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询公网 NAT 网关列表**。不创建/删除/修改 NAT 网关，也不查询
> SNAT 规则、DNAT 规则、中转 IP、私网 NAT 等其它 NAT 资源。
> 若用户询问"创建/删除 NAT 网关"、"查询 SNAT/DNAT 规则"等，
> 请明确告知本 Skill 不提供该能力。

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **Python 3.8+** with `huaweicloudsdknat` package installed (SDK fallback only)
3. **IAM permissions** — `nat:publicNatGateways:list` (or the system policy
   `NAT ReadOnlyAccess`) is required to list NAT gateways. See `references/iam-policies.md`
4. A region where the tenant owns NAT gateways; specify it with `--cli-region`

## Workflow

1. **Identify the intent** — Confirm the user wants to list public NAT gateways
   (and optionally the filters: status, spec, name, or name-only output).
2. **Confirm region** — Default `cn-north-4`; let the user override with another
   region if needed.
3. **Run the query** — Use the CLI command below with the requested filters.
4. **Present the results** — Show the gateway name, id, status, spec and VPC id
   for each gateway; on a name-list request, output just the names.
5. **Handle errors** — If the CLI fails (credentials/permissions/network), retry
   with the SDK fallback described in `references/verification-method.md`.

## Core Commands

> KooCLI format: `hcloud <Service> <Operation> --cli-region=<region> [--key=value]`

### List all public NAT gateways

```bash
hcloud NAT ListNatGateways --cli-region={region} --cli-output=json
```

### List only the NAT gateway names

```bash
hcloud NAT ListNatGateways --cli-region={region} --cli-output=json | jq -r '.nat_gateways[].name'
```

### Compact fields: name, id, status, spec

```bash
hcloud NAT ListNatGateways --cli-region={region} --cli-output=json \
  | jq -r '.nat_gateways[] | [.name, .id, .status, .spec] | @tsv'
```

### Filter by status

```bash
hcloud NAT ListNatGateways --cli-region={region} --status.1=ACTIVE --cli-output=json
```

Status enum: `ACTIVE`, `PENDING_CREATE`, `PENDING_UPDATE`, `PENDING_DELETE`, `INACTIVE`.

### Filter by spec

```bash
hcloud NAT ListNatGateways --cli-region={region} --spec.1=2 --cli-output=json
```

Spec options: `1` small, `2` medium, `3` large, `4` extra-large, `5` enterprise-class.

### Filter by name / enterprise project / pagination

```bash
hcloud NAT ListNatGateways --cli-region={region} --name={gateway-name} --cli-output=json
hcloud NAT ListNatGateways --cli-region={region} --enterprise_project_id={ep-id} --cli-output=json
hcloud NAT ListNatGateways --cli-region={region} --limit=50 --marker={last-id} --cli-output=json
```

### Sort results

```bash
hcloud NAT ListNatGateways --cli-region={region} --sort_key=created_at --sort_dir=desc --cli-output=json
```

### Quality-reporting wrapper script (recommended)

```bash
python3 scripts/list_nat_gateways.py --region={region} --names-only
python3 scripts/list_nat_gateways.py --region={region} --status ACTIVE --limit 20 --compact
```

The wrapper tries the CLI first, falls back to the `huaweicloudsdknat` SDK, and
reports execution quality to the skillsopr console. Set `SKILL_QUALITY_DISABLE=1`
to disable reporting (local debugging).

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `--status.[N]` | No | Gateway status filter (repeatable) | `--status.1=ACTIVE` |
| `--spec.[N]` | No | Gateway spec filter (repeatable) | `--spec.1=2` |
| `--name` | No | Gateway name filter (≤ 64 chars) | `nat-prod` |
| `--id` | No | Exact gateway id filter | `997d962d-...` |
| `--enterprise_project_id` | No | Enterprise project filter | `0` |
| `--limit` | No | Page size (1–2000, default 2000) | `50` |
| `--marker` | No | Pagination start resource id | `<last-gateway-id>` |
| `--sort_key` | No | Sort key: `id`/`name`/`status`/`created_at` | `created_at` |
| `--sort_dir` | No | Sort direction: `asc`/`desc` | `desc` |

## KooCLI Command Format Standard

The KooCLI command format is:

`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]`

> Note: this is a generic format template, not an executable command — replace
> `<Service>`, `<Operation>`, `<region>` and the parameters with real values
> (e.g. `hcloud NAT ListNatGateways --cli-region=cn-north-4`).

- Service name: `NAT` (starts with uppercase).
- Operation name: PascalCase — `ListNatGateways`.
- Region: always pass `--cli-region=<region>`.
- Simple parameters use `--key=value`, for example `--name=nat-prod`.
- Repeatable array parameters use the indexed form `--status.1=ACTIVE`,
  `--spec.1=2` (values per KooCLI indexed-parameter convention).

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Least-privilege IAM permissions
- [CLI Installation Guide](references/cli-installation-guide.md) — hcloud CLI setup and authentication
- [Verification Method](references/verification-method.md) — How to verify the skill works
- [Dataflow Diagram](references/dataflow-diagram.md) — Request flow diagram
- [Acceptance Criteria](references/acceptance-criteria.md) — Acceptance test checklist
