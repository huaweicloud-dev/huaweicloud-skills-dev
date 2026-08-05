---
name: huawei-cloud-swr-list
description: |
  Query the list of Huawei Cloud SWR (Software Repository for Container) image repositories under the current project/region. Lists all image repositories with their name, namespace, category, visibility (public/private), image/tag count, size, download count, full image path, tags and timestamps. Supports optional filtering by namespace, repository name (fuzzy match), category, and pagination (limit/offset) with sorting for account-wide repository inventory.
  Use when the user wants to: (1) list all Huawei Cloud SWR image repositories / 查询华为云SWR镜像仓库列表, (2) check how many image repositories exist in the account or region, (3) inspect repository visibility, size, tag count, or path for daily inspection or troubleshooting, (4) filter repositories by namespace, name, or category, (5) page through or sort repository results.
  Triggers include: "SWR列表", "华为云SWR列表", "查询SWR列表", "SWR镜像仓库列表", "容器镜像仓库列表", "SWR repository list", "list SWR repos", "ListReposDetails", "SWR仓库查询", "查看SWR仓库", "镜像仓库列表"
tags: ["huawei-cloud", "swr", "container", "repository-list", "image"]
---

# Huawei Cloud SWR Repository List Skill

## Overview

Query the list of Huawei Cloud SWR (Software Repository for Container) image repositories under the current account project and region.

This skill provides:

- List all image repositories in the current project/region
- Optional filter by namespace (`--namespace`), repository name fuzzy match (`--name`), or category (`--category`)
- Pagination (`--limit` / `--offset`) and sorting (`--order_column` / `--order_type`) for account-wide inventory
- Key repository attributes in the response: name, namespace, category, visibility, image/tag count, size, download count, full path, tags, timestamps
- CLI-first execution with Python SDK fallback

## Architecture

```
Huawei Cloud SWR Image Repository List
└── ListReposDetails  (GET /v2/manage/projects/{project_id}/repos)
    ├── CLI:  hcloud SWR ListReposDetails --cli-region=<region> [--param=value...]
    └── SDK:  huaweicloudsdkswr.v2.SwrClient.list_repos_details(ListReposDetailsRequest)
              → response.body (list of Repository objects)
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
> The SWR `ListReposDetails` API is region-scoped. If the user has repositories in
> multiple regions, run the query for each region of interest.

## IAM Permission Policies

The IAM user must be granted the SWR read permission. See [references/iam-policies.md](references/iam-policies.md).

**Minimum required permissions:**

- `swr:repository:list` — List SWR image repositories

## Core Workflows

### Task 1: List All Image Repositories

Query the full image repository list of the current project/region.

```bash
hcloud SWR ListReposDetails --cli-region={region} --limit=100
```

### Task 2: List Repositories in a Namespace

Filter by namespace (organization) name.

```bash
hcloud SWR ListReposDetails --cli-region={region} --namespace=group-dev --limit=100
```

### Task 3: Filter by Repository Name (Fuzzy Match)

Search repositories by name keyword.

```bash
hcloud SWR ListReposDetails --cli-region={region} --name=nginx --limit=100
```

### Task 4: Filter by Category

Filter by repository category (`app_server` / `linux` / `framework_app` / `database` / `lang` / `other` / `windows` / `arm`).

```bash
hcloud SWR ListReposDetails --cli-region={region} --category=database --limit=100
```

### Task 5: Paginated Listing with Sorting

Walk through all pages of image repositories.

```bash
# First page (limit 10, offset 0, sorted by update time descending)
hcloud SWR ListReposDetails --cli-region={region} --limit=10 --offset=0 --order_column=updated_time --order_type=desc

# Next page
hcloud SWR ListReposDetails --cli-region={region} --limit=10 --offset=10 --order_column=updated_time --order_type=desc

# Full JSON output (for agent consumption / parsing)
hcloud SWR ListReposDetails --cli-region={region} --limit=100 --cli-output=json
```

## Core Commands

| Command | Description |
|---------|-------------|
| `hcloud SWR ListReposDetails --cli-region={region} --limit=100` | List all image repositories in the project |
| `hcloud SWR ListReposDetails --cli-region={region} --namespace=group-dev` | Filter by namespace (organization) |
| `hcloud SWR ListReposDetails --cli-region={region} --name=nginx` | Filter by repository name (fuzzy match) |
| `hcloud SWR ListReposDetails --cli-region={region} --category=database` | Filter by category |
| `hcloud SWR ListReposDetails --cli-region={region} --limit=10 --offset=0` | Paginated listing |
| `hcloud SWR ListReposDetails --cli-region={region} --order_column=updated_time --order_type=desc` | Sorted listing |
| `hcloud SWR ListReposDetails --cli-region={region} --limit=100 --cli-output=json` | Full JSON output for parsing |

> **KooCLI parameter format:** all parameters use the `--param=value` (equals-sign) format.
> **Operation name:** the SWR repository list operation is `ListReposDetails`.
> **Response format:** a **flat JSON array** of repository objects (not wrapped in an object).
> **Response fields:** each item has `name`, `namespace`, `category`, `description`, `size`,
> `is_public`, `num_images` (image/tag count), `num_download`, `path` (full image path for
> docker pull), `internal_path`, `tags` (array of tag name strings), `created_at`, `updated_at`.
> An empty array `[]` is a valid result — it means no image repositories exist in that project/region.
> **Pagination:** `--limit` and `--offset` must be used together. Default limit is 100, max is 1000.
> **Sorting:** `--order_column` accepts `name`, `updated_time`, or `tag_count` (note: `tag_count`
> is the param value, the response field is `num_images`).

## Parameter Confirmation

> **Before executing any task, confirm the following parameters with the user. Guessing is prohibited.**

| Parameter | Required/Optional | Description | Default |
|-----------|------------------|-------------|---------|
| `{region}` | Required | Huawei Cloud region (e.g., `cn-north-4`); must be provided or resolved from the profile | - |
| `--namespace` | Optional | Namespace (organization) name to filter by | - |
| `--name` | Optional | Repository name keyword (fuzzy match) | - |
| `--category` | Optional | Repository category (`app_server` / `linux` / `framework_app` / `database` / `lang` / `other` / `windows` / `arm`) | - |
| `--limit` | Optional | Page size (number of repositories returned per call), max 1000 | 100 |
| `--offset` | Optional | Page offset (must pair with `--limit`) | 0 |
| `--order_column` | Optional | Sort column (`name` / `updated_time` / `tag_count`) | - |
| `--order_type` | Optional | Sort direction (`desc` / `asc`) | - |

## KooCLI Command Format Standard

```bash
hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | Exact KooCLI Service name beginning with uppercase/title case | `SWR` |
| Operation name | PascalCase | `ListReposDetails` |
| Region parameter | `--cli-region=<value>` | `--cli-region=cn-north-4` |
| Simple parameter | `--key=value` | `--namespace=group-dev` |

All concrete commands must use the `--param=value` equals-sign format.

## Verification Method

See [references/verification-method.md](references/verification-method.md) for details.

**Quick validation:**

```bash
# Confirm CLI works (returns repository list or empty array)
hcloud SWR ListReposDetails --cli-region=cn-north-4 --limit=10
```

## Reference Documents

| Document | Description |
|----------|-------------|
| [references/iam-policies.md](references/iam-policies.md) | Least-privilege IAM policy for listing SWR repositories |
| [references/verification-method.md](references/verification-method.md) | Verification steps and sample outputs |
| [references/dataflow-diagram.md](references/dataflow-diagram.md) | Mermaid data flow diagram |
| [references/acceptance-criteria.md](references/acceptance-criteria.md) | Acceptance criteria |
| [references/cli-installation-guide.md](references/cli-installation-guide.md) | CLI installation and authentication guide |
