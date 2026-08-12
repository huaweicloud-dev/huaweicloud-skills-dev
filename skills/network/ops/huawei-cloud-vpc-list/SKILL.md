---
name: huawei-cloud-vpc-list
description: |
  Query the list of Huawei Cloud Virtual Private Clouds (VPCs) belonging to the
  current tenant / project. Returns VPC id, name, CIDR block, status,
  description, enterprise project and other metadata. Supports filtering by
  VPC name, ID, CIDR block and enterprise project, pagination via limit/marker,
  and listing VPCs across all enterprise projects (all_granted_eps). Uses the
  KooCLI `hcloud VPC ListVpcs` command (primary) with v3/v2 API versions, or the
  huaweicloudsdkvpc Python SDK (fallback). Read-only — never creates, modifies
  or deletes any resource.
  Use this skill whenever the user wants to list/inspect the VPCs of the tenant,
  e.g. for network inventory, VPC planning, or troubleshooting.
  Triggers include: "query VPC list", "list VPCs", "VPC list", "查询VPC列表",
  "查询vpc列表", "VPC列表", "租户VPC列表", "查询租户的VPC", "list my vpcs",
  "how many VPCs", "VPC inventory".
tags:
  - huawei-cloud
  - vpc
  - list
  - network
  - query
---

# Huawei Cloud VPC List Skill

## Overview

This skill queries the list of **VPCs (Virtual Private Clouds)** under the current Huawei Cloud tenant / project and returns their key attributes (ID, name, CIDR, status, description, enterprise project). It is a read-only inspection skill: it never creates, modifies, or deletes VPCs or any related resources.

**Architecture:**

```
Agent → hcloud CLI (KooCLI, VPC ListVpcs, primary) → Huawei Cloud VPC API
       ↘ huaweicloudsdkvpc Python SDK (fallback)          ↗
```

**API versions supported:**

| Version | CLI Operation | API Path |
|---------|---------------|----------|
| v3 (recommended) | `VPC ListVpcs/v3` | `GET /v3/{project_id}/vpc/vpcs` |
| v2 (legacy) | `VPC ListVpcs/v2` | `GET /v1/{project_id}/vpcs` |

**Applicable Scenarios:**

- Network inventory: "list all VPCs of this tenant"
- VPC planning: verify existing CIDR ranges before creating new subnets/VPCs
- Troubleshooting: locate a VPC by name/id and inspect its status
- Enterprise-project audit: list VPCs of one enterprise project or all projects

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询 VPC 列表**。不创建/删除/修改 VPC，也不查询子网、安全组、
> 路由表等其它资源（那些属于 VPC 的其它查询能力或专用 Skill）。
> 若用户询问"查询子网/安全组/路由表"等，请明确告知本 Skill 不提供该能力。

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **IAM permissions** — `vpc:vpc:list` (or `vpc:*:list`) is required to list VPCs. See `references/iam-policies.md`
3. **Python 3.8+** with `huaweicloudsdkvpc` package (SDK fallback only) — `pip install huaweicloudsdkvpc`
4. **Region & Project** — the CLI uses the region and project bound to the configured AK/SK profile (`--cli-region` can be overridden)

## Workflow

1. **Confirm parameters** — ask the user for the target region (default `cn-north-4`), and any optional filters
2. **Verify prerequisites** — `hcloud version` and `hcloud configure list` to confirm authentication
3. **Run the query** — use the primary CLI command (v3 by default; v2 as compatibility fallback)
4. **Return results** — relay the VPC list (id, name, cidr, status, description, enterprise project id) to the user
5. **Handle pagination** — if more results than `limit`, use `--marker` with the next marker to fetch the next page
6. **Handle errors** — on auth/region errors, verify the profile/region and retry; on permission errors, report the missing IAM permission

## Core Commands

### List All VPCs (Recommended, v3)

```bash
hcloud VPC ListVpcs/v3 --cli-region={region}
```

### List VPCs with a Page Limit

```bash
hcloud VPC ListVpcs/v3 --cli-region={region} --limit={limit}
```

### Filter VPCs by Name

```bash
hcloud VPC ListVpcs/v3 --cli-region={region} --name.1={vpc_name}
```

### Filter VPCs by ID

```bash
hcloud VPC ListVpcs/v3 --cli-region={region} --id.1={vpc_id}
```

### Filter VPCs by CIDR Block

```bash
hcloud VPC ListVpcs/v3 --cli-region={region} --cidr.1={cidr}
```

### Filter VPCs by Enterprise Project

```bash
hcloud VPC ListVpcs/v3 --cli-region={region} --enterprise_project_id={enterprise_project_id}
```

### List VPCs of All Enterprise Projects

```bash
hcloud VPC ListVpcs/v3 --cli-region={region} --enterprise_project_id=all_granted_eps
```

### Paginate with Marker

```bash
hcloud VPC ListVpcs/v3 --cli-region={region} --limit={limit} --marker={next_marker}
```

### Legacy v2 API (Compatibility)

```bash
hcloud VPC ListVpcs/v2 --cli-region={region} --limit={limit}
```

> For JSON output, add `--cli-output=json` to any command.

## Parameter Confirmation

| Parameter | Required | Description | Example |
| --------- | -------- | ----------- | ------- |
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `{limit}` | No | Number of records per page (v3: 0–2000) | `20` |
| `{vpc_name}` | No | Filter by VPC name (v3 array: `--name.1=...`) | `tf-web-vpc` |
| `{vpc_id}` | No | Filter by VPC ID (v3 array: `--id.1=...`) | `04a09970-...` |
| `{cidr}` | No | Filter by CIDR block (v3 array: `--cidr.1=...`) | `192.168.0.0/16` |
| `{enterprise_project_id}` | No | Enterprise project ID; `0` = default, `all_granted_eps` = all | `all_granted_eps` |
| `{next_marker}` | No | Start ID for the next page (pagination) | from previous result |

## Reference Documents

- [CLI Installation Guide](references/cli-installation-guide.md)
- [IAM Policies](references/iam-policies.md)
- [Verification Method](references/verification-method.md)
- [Data Flow Diagram](references/dataflow-diagram.md)
- [Acceptance Criteria](references/acceptance-criteria.md)

## KooCLI Command Format Standard

```bash
hcloud VPC ListVpcs/v3 --cli-region=<region> [--key=value ...]
```

| Feature | Description | Example |
| ------- | ----------- | ------- |
| Service name | `VPC` (title-case KooCLI service name) | `hcloud VPC ...` |
| Operation name | `ListVpcs` in PascalCase, with API version suffix | `ListVpcs/v3`, `ListVpcs/v2` |
| Region parameter | `--cli-region=<value>` is required | `--cli-region=cn-north-4` |
| Simple parameter | `--key=value` | `--limit=20` |
| Array parameter | `--key.N=value` (v3 filters) | `--name.1=tf-web-vpc` |
| Output format | `--cli-output=json` for machine-readable output | `--cli-output=json` |
