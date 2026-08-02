---
name: huawei-cloud-cce-query
description: >-
  Query Huawei Cloud CCE (Cloud Container Engine) clusters and report their
  names, IDs, statuses, versions, and node information across a project.
  Use when listing CCE clusters, looking up a cluster name, showing cluster
  detail, or inspecting cluster status and nodes. Provides read-only
  inspection for daily operations, inventory reporting, and troubleshooting.
  Triggers include: CCE query, list CCE clusters, query CCE cluster names,
  CCE cluster inventory, show CCE cluster, list CCE nodes, check cluster status,
  CCE集群查询, 查询CCE集群, CCE集群名称, CCE集群列表, 查看CCE集群.
tags:
  - huawei-cloud
  - cce
  - query
  - kubernetes
  - container
---

# Huawei Cloud CCE Query Skill

## Overview

This skill provides read-only query capabilities for Huawei Cloud CCE (Cloud Container Engine,
the managed Kubernetes service). It lists all clusters in a project with their names, IDs,
status, version and flavor, shows a single cluster's detail, and lists nodes for a given
cluster. It is designed for inventory reporting, daily inspection, and quick name lookups.

**Architecture:**

```
Agent → hcloud CLI (primary) → Huawei Cloud CCE API
       ↘ Python SDK (fallback) ↗
```

**Applicable Scenarios:**

- Inventory all CCE clusters and collect their names in a region
- Check cluster health/status (Available, Creating, Upgrading, Deleting, etc.)
- Retrieve a specific cluster's detail by ID or name
- List the nodes inside a cluster for capacity/usage review

## Prerequisites

1. **hcloud CLI** installed and authenticated — See `references/cli-installation-guide.md`
2. **Python 3.8+** with `huaweicloudsdkcce` package (SDK fallback)
3. **Huawei Cloud AK/SK** configured via environment variables or `hcloud configure set`
4. **IAM permissions** — `CCE ReadOnlyAccess` or finer-grained policy — See `references/iam-policies.md`

## Workflow

1. **Identify query scope** — Decide whether to list all clusters, show one cluster detail, or list nodes of a cluster
2. **Select execution mode** — Use the hcloud CLI by default; fall back to the Python SDK if the CLI is unavailable
3. **Execute the query** — Run the appropriate command and capture the response
4. **Present results** — Summarize cluster names, IDs, statuses and node counts in a readable form

## Core Commands

### Cluster Queries

| Purpose | Command |
|---------|---------|
| List all CCE clusters (names, IDs, status) | `hcloud CCE ListClusters --cli-region={region}` |
| List clusters with a status filter | `hcloud CCE ListClusters --cli-region={region} --status={status}` |
| List clusters of a given type | `hcloud CCE ListClusters --cli-region={region} --type={type}` |
| List clusters with node/addon detail | `hcloud CCE ListClusters --cli-region={region} --detail=true` |
| Show a single cluster's detail | `hcloud CCE ShowCluster --cli-region={region} --cluster_id={cluster_id}` |

### Node Queries

| Purpose | Command |
|---------|---------|
| List nodes in a cluster | `hcloud CCE ListNodes --cli-region={region} --cluster_id={cluster_id}` |
| Show a single node's detail | `hcloud CCE ShowNode --cli-region={region} --cluster_id={cluster_id} --node_id={node_id}` |

### Name-Only Lookup (jq)

To extract just the cluster names:

```bash
hcloud CCE ListClusters --cli-region={region} | jq -r '.items[].metadata.name'
```

### SDK Fallback Examples

When the CLI is unavailable, use the Python SDK:

```python
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkcce.v3.region.cce_region import CceRegion
from huaweicloudsdkcce.v3 import CceClient, ListClustersRequest

credentials = BasicCredentials() \
    .with_ak(os.getenv("HUAWEI_ACCESS_KEY")) \
    .with_sk(os.getenv("HUAWEI_SECRET_KEY")) \
    .with_project_id("{project_id}")

client = CceClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(CceRegion.value_of("{region}")) \
    .build()

request = ListClustersRequest()
response = client.list_clusters(request)
for cluster in response.items:
    print(cluster.metadata.name, cluster.status.phase)
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `{cluster_id}` | Conditional | CCE cluster ID (required for ShowCluster/ListNodes) | `0ef72478-4e7e-11f1-a40f-0255ac100246` |
| `{node_id}` | Conditional | CCE node ID (required for ShowNode) | `d4f16c73-...` |
| `{status}` | No | Cluster status filter | `Available` |
| `{type}` | No | Cluster type filter | `VirtualMachine` |
| `{project_id}` | Conditional | Project ID (required for SDK/API) | `0a1234b56c78d9ef` |

## Reference Documents

- [CLI Installation Guide](references/cli-installation-guide.md)
- [IAM Policies](references/iam-policies.md)
- [Verification Method](references/verification-method.md)
- [Data Flow Diagram](references/dataflow-diagram.md)
- [Acceptance Criteria](references/acceptance-criteria.md)

## KooCLI Command Format Standard

```bash
hcloud CCE <Operation> --cli-region=<region> [--key=value ...]
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | `CCE` | `hcloud CCE ListClusters` |
| Operation name | PascalCase | `ListClusters`, `ShowCluster`, `ListNodes` |
| Region parameter | `--cli-region=<value>` | `--cli-region=cn-north-4` |
| Simple parameter | `--key=value` | `--cluster_id=xxx` |
