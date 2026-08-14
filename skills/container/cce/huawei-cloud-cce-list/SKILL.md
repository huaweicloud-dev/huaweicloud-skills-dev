---
name: huawei-cloud-cce-list
description: |
  Query the list of Huawei Cloud CCE (Cloud Container Engine) clusters under
  the current tenant / project, focused on the CCE cluster NAME list. Returns
  each cluster's name, id, status (phase), version and flavor. Supports
  filtering by status and cluster type, and extracting a pure cluster-name
  list. Uses the KooCLI command `hcloud CCE ListClusters --cli-region={region}`
  (primary) against the v3 API, or the huaweicloudsdkcce Python SDK (fallback).
  Read-only — never creates, modifies or deletes any cluster or node.
  Use this skill whenever the user wants to list/inspect the CCE clusters of
  the tenant or query the CCE cluster name list, e.g. for CCE cluster
  inventory, daily inspection, or cost review.
  Triggers include: "list CCE clusters", "CCE cluster list", "query CCE
  cluster names", "CCE name list", "CCE集群列表", "查询CCE集群", "CCE集群名称列表",
  "CCE集群名称", "list cce", "cce list", "how many CCE clusters".
tags:
  - huawei-cloud
  - cce
  - list
  - kubernetes
  - query
---

# Huawei Cloud CCE Cluster List Skill

## Overview

This skill queries the list of **CCE (Cloud Container Engine) clusters** under the
current Huawei Cloud tenant / project and returns their key attributes — in particular
the **CCE cluster name list** (`metadata.name`), along with `id` (`metadata.uid`),
`status` (`status.phase`), Kubernetes `version` and `flavor`. It is a read-only
inspection skill: it never creates, modifies, or deletes clusters, nodes, or any
related resources.

**Architecture:**

```text
Agent → hcloud CLI (KooCLI, CCE ListClusters, primary) → Huawei Cloud CCE v3 API
       ↘ huaweicloudsdkcce Python SDK (fallback)              ↗
```

**API path (verified from `huaweicloudsdkcce` v3 SDK `_list_clusters_http_info`):**

| Operation | Method | API Path |
|-----------|--------|----------|
| List clusters | GET | `/api/v3/projects/{project_id}/clusters` |

**Applicable Scenarios:**

- CCE cluster inventory: "list all CCE clusters of this tenant" or "show me the CCE cluster name list"
- Daily inspection: snapshot of all clusters with their status and version
- Cost review: enumerate clusters and their flavor to spot unused or oversized resources
- Fast lookup: retrieve the exact cluster name(s) for follow-up operations

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询 CCE 集群列表**。不创建/删除/修改集群，也不查询/操作集群内的
> 节点（node）、节点池（nodepool）、Addon 等其它资源。若用户询问"创建/删除/扩容集群"、
> "查询集群节点"、"获取 kubeconfig"等，请明确告知本 Skill 不提供该能力。
> 单集群详情（show-by-id）查询不在本 Skill 范围内，请使用对应的 CCE 详情/管理类 skill。

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **Python 3.8+** with `huaweicloudsdkcce` package installed (SDK fallback only)
3. **IAM permissions** — `cce:cluster:list` (or the system policy `CCE ReadOnlyAccess`)
   is required to list clusters. See `references/iam-policies.md`
4. A region where the tenant owns CCE clusters; specify it with `--cli-region`

## Workflow

1. **Identify the intent** — Confirm the user wants to list CCE clusters (and optionally
   the filters: status, cluster type, or name-only output).
2. **Confirm region** — Default `cn-north-4`; let the user override with another region
   if needed.
3. **Run the query** — Use the CLI command below with the requested filters.
4. **Present the results** — Show the cluster name, id, status and version for each
   cluster; on a name-list request, output just the names.
5. **Handle errors** — If the CLI fails (credentials/permissions/network), retry with
   the SDK fallback described in `references/verification-method.md`.

## Core Commands

> KooCLI format: `hcloud <Service> <Operation> --cli-region=<region> [--key=value]`

### List all CCE clusters (names, ids, status)

```bash
hcloud CCE ListClusters --cli-region={region} --cli-output=json
```

### List only the CCE cluster names

```bash
hcloud CCE ListClusters --cli-region={region} --cli-output=json | jq -r '.items[].metadata.name'
```

### Compact fields: name, id, status, version

```bash
hcloud CCE ListClusters --cli-region={region} --cli-output=json \
  | jq -r '.items[] | [.metadata.name, .metadata.uid, .status.phase, .spec.version] | @tsv'
```

### Filter by cluster status

```bash
hcloud CCE ListClusters --cli-region={region} --status=Available --cli-output=json
```

Status enum: `Available`, `Unavailable`, `ScalingUp`, `ScalingDown`, `Creating`,
`Deleting`, `Upgrading`, `Resizing`, `RollingBack`, `RollbackFailed`, `Empty`.

### Filter by cluster type

```bash
hcloud CCE ListClusters --cli-region={region} --type=VirtualMachine --cli-output=json
```

Type options: `VirtualMachine` (CCE cluster), `ARM64` (Kunpeng cluster).

### Include node/addon detail

```bash
hcloud CCE ListClusters --cli-region={region} --detail=true --cli-output=json
```

> **Note:** In the CCE v3 list response, the cluster **name** is `metadata.name`
> (and `metadata.alias` is usually the same value). The cluster **id** is
> `metadata.uid`, the cluster **status** is `status.phase`, and the Kubernetes
> version is `spec.version`.

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `{status}` | No | Cluster status filter | `Available` |
| `{type}` | No | Cluster type filter | `VirtualMachine` |

## KooCLI Command Format Standard

The KooCLI command format is:

`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]`

> Note: this is a generic format template, not an executable command — replace
> `<Service>`, `<Operation>`, `<region>` and the parameters with real values
> (e.g. `hcloud CCE ListClusters --cli-region=cn-north-4`).

- Service name: `CCE` (starts with uppercase).
- Operation name: PascalCase — `ListClusters`.
- Region: always pass `--cli-region=<region>`.
- Simple parameters use `--key=value`, for example `--status=Available`.

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Least-privilege IAM permissions
- [CLI Installation Guide](references/cli-installation-guide.md) — hcloud CLI setup and authentication
- [Verification Method](references/verification-method.md) — How to verify the skill works
- [Dataflow Diagram](references/dataflow-diagram.md) — Request flow diagram
- [Acceptance Criteria](references/acceptance-criteria.md) — Acceptance test checklist
