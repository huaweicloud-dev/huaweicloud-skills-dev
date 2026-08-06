---
name: huawei-cloud-swr-namespace-list
description: |
  Query the list of Huawei Cloud SWR (Software Repository for Container) namespaces (organizations) under the current project/region. Lists all namespaces with their ID, name, creator, auth level, access user count and repository count. Supports optional filtering by namespace name. This is the top-level resource listing for SWR — namespaces organize image repositories into groups.
  Use when the user wants to: (1) list all Huawei Cloud SWR namespaces / 查询华为云SWR组织列表, (2) check how many SWR organizations exist in the account or region, (3) inspect namespace auth level, repository count, or creator for daily inspection or troubleshooting, (4) filter namespaces by name.
  Triggers include: "SWR组织列表", "华为云SWR组织列表", "查询SWR组织", "SWR namespace list", "list SWR namespaces", "ListNamespaces", "SWR命名空间列表", "查看SWR组织", "SWR名称列表"
tags: ["huawei-cloud", "swr", "container", "namespace-list", "organization"]
---

# Huawei Cloud SWR Namespace (Organization) List Skill

## Overview

Query the list of Huawei Cloud SWR (Software Repository for Container) namespaces (organizations) under the current account project and region. Namespaces are the top-level organizational unit in SWR — they group image repositories.

This skill provides:

- List all namespaces (organizations) in the current project/region
- Optional filter by namespace name (`--namespace`) or complex filter (`--filter`)
- Key namespace attributes in the response: ID, name, creator, auth level, access user count, repository count
- CLI-first execution with Python SDK fallback

> **Read-only skill**: 本 skill 仅支持 SWR 命名空间只读查询（ListNamespaces），不支持创建、删除、修改等写操作。如需写操作，请使用 `huawei-cloud-swr-image-management` skill。

## Architecture

```
Huawei Cloud SWR Namespace (Organization) List
└── ListNamespaces  (GET /v2/manage/projects/{project_id}/namespaces)
    ├── CLI:  hcloud SWR ListNamespaces --cli-region=<region> [--param=value...]
    └── SDK:  huaweicloudsdkswr.v2.SwrClient.list_namespaces(ListNamespacesRequest)
              → response.namespaces (list of Namespace objects)
```

## Prerequisites

> **Prerequisite check: Huawei Cloud CLI (hcloud / KooCLI) >= 3.2.0 required**
> Check the CLI version (run hcloud with the `version` argument) and confirm a
> version string is printed. If not installed or too old, see
> [references/cli-installation-guide.md](references/cli-installation-guide.md).

> **Prerequisite check: Huawei Cloud credentials required**
> Check the CLI profile (run hcloud with the `configure list` arguments) and
> confirm a profile with valid AK/SK exists. Credentials must be read from the
> configured CLI profile or environment variables. Never ask for or echo AK/SK
> values in the conversation.

> **Prerequisite check: SWR (Software Repository for Container) enabled for the account**
> The SWR `ListNamespaces` API is region-scoped. If the user has namespaces in
> multiple regions, run the query for each region of interest.

## IAM Permission Policies

The IAM user must be granted the SWR read permission. See [references/iam-policies.md](references/iam-policies.md).

**Minimum required permissions:**

- `swr:namespace:list` — List SWR namespaces

## Core Workflows

### Task 1: List All Namespaces

Query the full namespace (organization) list of the current project/region.

```bash
hcloud SWR ListNamespaces --cli-region={region}
```

### Task 2: Filter by Namespace Name

Filter namespaces by a specific name.

```bash
hcloud SWR ListNamespaces --cli-region={region} --namespace=group-dev
```

### Task 3: Complex Filter

Filter using a complex filter expression.

```bash
# Filter by namespace name and visibility mode
hcloud SWR ListNamespaces --cli-region={region} --filter="namespace::group-dev|mode::visible"
```

### Task 4: Full JSON Output

Output as JSON for agent consumption and parsing.

```bash
hcloud SWR ListNamespaces --cli-region={region} --cli-output=json
```

## Core Commands

| Command | Description |
|---------|-------------|
| `hcloud SWR ListNamespaces --cli-region={region}` | List all namespaces in the project |
| `hcloud SWR ListNamespaces --cli-region={region} --namespace=group-dev` | Filter by namespace name |
| `hcloud SWR ListNamespaces --cli-region={region} --filter="namespace::group-dev\|mode::visible"` | Complex filter |
| `hcloud SWR ListNamespaces --cli-region={region} --cli-output=json` | Full JSON output for parsing |

> **KooCLI parameter format:** all parameters use the `--param=value` (equals-sign) format.
> **Operation name:** the SWR namespace list operation is `ListNamespaces`.
> **Response format:** a JSON object with a `namespaces` array.
> **Response fields:** each item has `id` (numeric namespace ID), `name` (namespace name),
> `creator_name` (creator IAM user name), `auth` (permission level: 7=manage, 3=edit, 1=read),
> `access_user_count` (number of users with access), `repo_count` (number of repositories under
> this namespace). An empty `namespaces` array is a valid result — it means no SWR namespaces
> exist in that project/region.
> **SDK model note**: the SDK `Namespace` model maps `id`, `name`, `creator_name`, and `auth` only;
> `access_user_count` and `repo_count` are returned by the CLI/API but not mapped in the SDK model.
> **No pagination:** `ListNamespaces` returns all namespaces; `--limit`/`--offset` are not supported.

## Parameter Confirmation

> **Before executing any task, confirm the following parameters with the user. Guessing is prohibited.**

| Parameter | Required/Optional | Description | Default |
|-----------|------------------|-------------|---------|
| `{region}` | Required | Huawei Cloud region (e.g., `cn-north-4`); must be provided or resolved from the profile | - |
| `--namespace` | Optional | Namespace name to filter by | - |
| `--filter` | Optional | Complex filter expression (e.g., `namespace::{name}\|mode::{mode}`) | - |

## KooCLI Command Format Standard

```bash
hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | Exact KooCLI Service name beginning with uppercase/title case | `SWR` |
| Operation name | PascalCase | `ListNamespaces` |
| Region parameter | `--cli-region=<value>` | `--cli-region=cn-north-4` |
| Simple parameter | `--key=value` | `--namespace=group-dev` |

All concrete commands must use the `--param=value` equals-sign format.

## Verification Method

See [references/verification-method.md](references/verification-method.md) for details.

**Quick validation:**

```bash
# Confirm CLI works (returns namespace list or empty array)
hcloud SWR ListNamespaces --cli-region=cn-north-4
```

## Reference Documents

| Document | Description |
|----------|-------------|
| [references/iam-policies.md](references/iam-policies.md) | Least-privilege IAM policy for listing SWR namespaces |
| [references/verification-method.md](references/verification-method.md) | Verification steps and sample outputs |
| [references/dataflow-diagram.md](references/dataflow-diagram.md) | Mermaid data flow diagram |
| [references/acceptance-criteria.md](references/acceptance-criteria.md) | Acceptance criteria |
| [references/cli-installation-guide.md](references/cli-installation-guide.md) | CLI installation and authentication guide |
