---
name: huawei-cloud-dcs-list
description: >-
  Query Huawei Cloud DCS (Distributed Cache Service) instance names and list
  all managed Redis/Memcached instances across a region. Provides read-only
  name lookup, name filtering, status-based filtering, and
  instance ID lookup for inventory reporting and daily inspection.
  Triggers include: DCS list, list DCS instances, query DCS names,
  DCS instance name, find DCS instance, DCS name lookup, DCS instance list,
  Redis instance names, cache instance names, DCS inventory,
  查询DCS名称, DCS实例名称, 缓存实例名称, DCS列表, DCS实例列表,
  查询缓存实例名称.
tags:
  - huawei-cloud
  - dcs
  - list
  - redis
  - inventory
---

# Huawei Cloud DCS List Skill

## Overview

This skill provides read-only name-query capabilities for Huawei Cloud DCS (Distributed Cache Service,
i.e. managed Redis / Memcached). It lists all DCS instances in a region, extracts instance names, and
supports filtering by name and status, and instance ID lookup. It is designed for quick name
lookups, inventory reporting, and daily instance inspection.

**Architecture:**

```
Agent → hcloud CLI (primary) → Huawei Cloud DCS API
       ↘ Python SDK (fallback) ↗
```

**Applicable Scenarios:**

- List all DCS instance names in a region for inventory
- Find a DCS instance by name (fuzzy or exact match)
- Check which instances are in a given status (RUNNING, etc.)
- Look up a specific instance by ID for cross-reference

## Prerequisites

1. **hcloud CLI** installed and authenticated — See `references/cli-installation-guide.md`
2. **Python 3.8+** with `huaweicloudsdkdcs` package (SDK fallback)
3. **Huawei Cloud AK/SK** configured via environment variables or `hcloud configure set`
4. **IAM permissions** — `DCS ReadOnlyAccess` or finer-grained policy — See `references/iam-policies.md`

## Workflow

1. **Identify query scope** — Decide whether to list all DCS instances, filter by name, status, or instance ID
2. **Select execution mode** — Use the hcloud CLI by default; fall back to the Python SDK if the CLI is unavailable
3. **Execute the query** — Run the appropriate command and capture the response
4. **Present results** — Summarize DCS instance names, IDs and statuses in a readable form

> **Note on exact name matching:** The DCS `ListInstances` API documents a `name_equal` query parameter
> for exact-match filtering. In current deployments it can return empty results even for existing names,
> so the fuzzy `--name` filter is the reliable way to look up an instance by name; use the returned
> `instance_id` with `ShowInstance` for precise detail.

## Core Commands

### Instance Name Queries

| Purpose | Command |
|---------|---------|
| List all DCS instances | `hcloud DCS ListInstances --cli-region={region} --limit={limit}` |
| List instances filtered by name (fuzzy) | `hcloud DCS ListInstances --cli-region={region} --name={name} [--limit={limit}]` |
| List instances filtered by status | `hcloud DCS ListInstances --cli-region={region} --status={status} [--limit={limit}]` |
| List instances filtered by instance ID | `hcloud DCS ListInstances --cli-region={region} --instance_id={instance_id}` |
| Show a single instance's detail | `hcloud DCS ShowInstance --cli-region={region} --instance_id={instance_id}` |

### Name-Only Lookup (jq)

To extract just the instance names:

```bash
hcloud DCS ListInstances --cli-region={region} --limit={limit} | jq -r '.instances[].name'
```

To list instance names with status:

```bash
hcloud DCS ListInstances --cli-region={region} --limit={limit} | jq -r '.instances[] | "\(.name)\t\(.status)\t\(.instance_id)"'
```

### SDK Fallback Examples

When the CLI is unavailable, use the Python SDK:

```python
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkdcs.v2.region.dcs_region import DcsRegion
from huaweicloudsdkdcs.v2 import dcs_client
from huaweicloudsdkdcs.v2.model import ListInstancesRequest

credentials = BasicCredentials() \
    .with_ak(os.getenv("HUAWEI_ACCESS_KEY")) \
    .with_sk(os.getenv("HUAWEI_SECRET_KEY")) \
    .with_project_id("{project_id}")

client = dcs_client.DcsClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(DcsRegion.value_of("{region}")) \
    .build()

request = ListInstancesRequest()
request.limit = 100
response = client.list_instances(request)
for instance in response.instances:
    print(instance.name, instance.status, instance.instance_id)
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `{name}` | No | DCS instance name filter (fuzzy match) | `dcs-eval-client` |
| `{status}` | No | Instance status filter | `RUNNING` |
| `{instance_id}` | No | Instance ID filter / required for ShowInstance | `51bb645e-d27f-465d-8192-c912d134756c` |
| `{limit}` | No | Maximum records to return (1-1000, default 10) | `100` |
| `{project_id}` | Conditional | Project ID (required for SDK/API) | `0a1234b56c78d9ef` |

## Reference Documents

- [CLI Installation Guide](references/cli-installation-guide.md)
- [IAM Policies](references/iam-policies.md)
- [Verification Method](references/verification-method.md)
- [Data Flow Diagram](references/dataflow-diagram.md)
- [Acceptance Criteria](references/acceptance-criteria.md)

## KooCLI Command Format Standard

```bash
hcloud DCS <Operation> --cli-region=<region> [--key=value ...]
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | `DCS` | `hcloud DCS ListInstances` |
| Operation name | PascalCase | `ListInstances`, `ShowInstance` |
| Region parameter | `--cli-region=<value>` | `--cli-region=cn-north-4` |
| Simple parameter | `--key=value` | `--name=dcs-eval-client` |
