---
name: huawei-cloud-css-list
description: |
  Query the list of Huawei Cloud CSS (Cloud Search Service) Elasticsearch (ES) clusters under the current project/region. Lists all ES clusters with their ID, name, status, endpoint, datastore engine/version, instance configuration, VPC/subnet/security-group, tags and enterprise project. Supports optional filtering by datastore engine type and pagination (limit/offset) for account-wide cluster inventory.
  Use when the user wants to: (1) list all Huawei Cloud ES clusters / 查询华为云ES列表, (2) check how many Elasticsearch clusters exist in the account or region, (3) inspect ES cluster status, endpoint, version, or node configuration for daily inspection or troubleshooting, (4) filter ES clusters by engine type (elasticsearch/logstash/opensearch) or page through results.
  Triggers include: "ES列表", "华为云ES列表", "查询ES列表", "ES集群列表", "elasticsearch列表", "list ES clusters", "ES cluster list", "云搜索服务列表", "CSS列表", "css list", "ListClusters", "ES集群查询", "查看ES集群"
tags: ["huawei-cloud", "css", "elasticsearch", "es", "cluster-list"]
---

# Huawei Cloud CSS (Elasticsearch) List Skill

## Overview

Query the list of Huawei Cloud CSS (Cloud Search Service) clusters — the managed Elasticsearch (ES) service — under the current account project and region.

This skill provides:

- List all ES clusters in the current project/region
- Optional filter by datastore engine type (`elasticsearch` / `logstash` / `opensearch`)
- Pagination (`--limit` / `--offset`) for account-wide inventory
- Key cluster attributes in the response: ID, name, status, endpoint, datastore (engine + version), instances, VPC/subnet/security group, enterprise project, tags
- CLI-first execution with Python SDK fallback

## Architecture

```
Huawei Cloud CSS (Elasticsearch) Cluster List
└── ListClustersDetails  (GET /v1.0/{project_id}/clusters)
    ├── CLI:  hcloud CSS ListClustersDetails --cli-region=<region> [--param=value...]
    └── SDK:  huaweicloudsdkcss.v1.CssClient.list_clusters_details(ListClustersDetailsRequest)
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

> **Prerequisite check: CSS (Cloud Search Service) enabled for the account**
> The CSS `ListClustersDetails` API is region-scoped. If the user has clusters in
> multiple regions, run the query for each region of interest.

## IAM Permission Policies

The IAM user must be granted the CSS read permission. See [references/iam-policies.md](references/iam-policies.md).

**Minimum required permissions:**

- `css:cluster:list` — List CSS clusters

## Core Workflows

### Task 1: List All ES Clusters

Query the full ES cluster list of the current project/region.

```bash
hcloud CSS ListClustersDetails --cli-region={region} --limit=100
```

### Task 2: List Only Elasticsearch Clusters

Filter by datastore engine type (`elasticsearch` / `logstash` / `opensearch`).

```bash
hcloud CSS ListClustersDetails --cli-region={region} --datastoreType=elasticsearch --limit=100
hcloud CSS ListClustersDetails --cli-region={region} --datastoreType=opensearch --limit=100
```

### Task 3: Paginated Listing

Walk through all pages of ES clusters.

```bash
# First page (limit 10, offset 1)
hcloud CSS ListClustersDetails --cli-region={region} --limit=10 --offset=1

# Next page
hcloud CSS ListClustersDetails --cli-region={region} --limit=10 --offset=11

# Full JSON output (for agent consumption / parsing)
hcloud CSS ListClustersDetails --cli-region={region} --limit=100 --cli-output=json
```

## Core Commands

| Command | Description |
|---------|-------------|
| `hcloud CSS ListClustersDetails --cli-region={region} --limit=100` | List all ES clusters in the project |
| `hcloud CSS ListClustersDetails --cli-region={region} --datastoreType=elasticsearch` | Filter by engine type (`elasticsearch` / `logstash` / `opensearch`) |
| `hcloud CSS ListClustersDetails --cli-region={region} --limit=10 --offset=1` | Paginated listing |
| `hcloud CSS ListClustersDetails --cli-region={region} --limit=100 --cli-output=json` | Full JSON output for parsing |

> **KooCLI parameter format:** all parameters use the `--param=value` (equals-sign) format.
> **Operation name:** the CSS list operation is `ListClustersDetails` (not `ListClusters`).
> **Response fields:** `totalSize` = cluster count; `clusters[]` = array of cluster objects
> (`id`, `name`, `status`, `endpoint`, `datastore`, `instances`, `created`, `updated`, `vpcId`,
> `subnetId`, `securityGroupId`, `enterpriseProjectId`, `tags`, etc.). An empty `clusters` array is a
> valid result — it means no ES clusters exist in that project/region.
> **Cluster status values:** `100` = creating, `200` = available, `300` = unavailable,
> `303` = creation failed.

## Parameter Confirmation

> **Before executing any task, confirm the following parameters with the user. Guessing is prohibited.**

| Parameter | Required/Optional | Description | Default |
|-----------|------------------|-------------|---------|
| `{region}` | Required | Huawei Cloud region (e.g., `cn-north-4`); must be provided or resolved from the profile | - |
| `--datastoreType` | Optional | Filter by datastore engine type (`elasticsearch` / `logstash` / `opensearch`) | - |
| `--limit` | Optional | Page size (number of clusters returned per call) | 10 |
| `--offset` | Optional | Start value of the query (default 1) | 1 |

## KooCLI Command Format Standard

```bash
hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | Exact KooCLI Service name beginning with uppercase/title case | `CSS` |
| Operation name | PascalCase | `ListClustersDetails` |
| Region parameter | `--cli-region=<value>` | `--cli-region=cn-north-4` |
| Simple parameter | `--key=value` | `--datastoreType=elasticsearch` |

All concrete commands must use the `--param=value` equals-sign format.

## Verification Method

See [references/verification-method.md](references/verification-method.md) for details.

**Quick validation:**

```bash
# Confirm CLI works (returns cluster list or empty array)
hcloud CSS ListClustersDetails --cli-region=cn-north-4 --limit=10
```

## Reference Documents

| Document | Description |
|----------|-------------|
| [references/iam-policies.md](references/iam-policies.md) | Least-privilege IAM policy for listing CSS clusters |
| [references/verification-method.md](references/verification-method.md) | Verification steps and sample outputs |
| [references/dataflow-diagram.md](references/dataflow-diagram.md) | Mermaid data flow diagram |
| [references/acceptance-criteria.md](references/acceptance-criteria.md) | Acceptance criteria |
| [references/cli-installation-guide.md](references/cli-installation-guide.md) | CLI installation and authentication guide |
