---
name: huawei-cloud-gaussdb-count
description: >-
  Count the number of Huawei Cloud GaussDB instances in a region and report
  their total storage size (GB). Covers both GaussDB for openGauss and GaussDB
  (MySQL-compatible) instances. Returns the authoritative total_count from the
  list API and sums the per-instance volume size, so the reported number and
  size are always correct. Read-only — never creates, modifies or deletes any
  resource.
  Use for GaussDB database inventory, daily inspection, or cost review.
  Triggers include: count GaussDB, GaussDB count, GaussDB instance
  count, how many GaussDB instances, GaussDB数量, GaussDB实例数量,
  查询GaussDB数量, GaussDB总数, 统计GaussDB实例数, GaussDB大小,
  GaussDB存储大小, GaussDB storage size, GaussDB size.
tags:
  - huawei-cloud
  - gaussdb
  - count
  - database
  - inventory
---

# Huawei Cloud GaussDB Count Skill

## Overview

This skill queries the total number of Huawei Cloud GaussDB instances in a
region and reports their total storage size (GB). It supports both GaussDB
product families:

- **GaussDB for openGauss** — primary/standby (Ha) and distributed (Enterprise)
  instances, queried via the `GaussDBforopenGauss` service.
- **GaussDB (MySQL-compatible)** — instances queried via the `GaussDB` service.

The count is taken from the authoritative `total_count` field returned by the
list API, so the result is exact regardless of page size — no pagination sum is
needed for the count itself. The storage size is the sum of each instance's
`volume.size` field (in GB) returned by the same list API.

**Architecture:**

```
Agent → hcloud CLI (primary) → Huawei Cloud GaussDB API
       ↘ Python SDK (fallback) ↗
```

**Applicable Scenarios:**

- Daily inspection: how many GaussDB instances exist in a region and their total size
- Database inventory, storage planning and cost review
- Capacity planning and pre-migration verification

## Prerequisites

1. **hcloud CLI** installed and authenticated — See `references/cli-installation-guide.md`
2. **Python 3.8+** with `huaweicloudsdkgaussdbforopengauss` and `huaweicloudsdkgaussdb`
   packages (SDK fallback)
3. **Huawei Cloud AK/SK** configured via environment variables or the hcloud CLI profile
4. **IAM permissions** — read-only access to GaussDB instances — See `references/iam-policies.md`

## Workflow

1. **Identify query scope** — Decide which region to query
2. **Select execution mode** — Use the hcloud CLI by default; fall back to the Python SDK if the CLI is unavailable
3. **Execute the query** — Run the list commands and capture `total_count` plus each instance's `volume.size`
4. **Present results** — Output the GaussDB instance count and total storage size to the user

## Core Commands

### Count GaussDB for openGauss Instances

| Purpose | Command |
|---------|---------|
| Count all GaussDB for openGauss instances | `hcloud GaussDBforopenGauss ListInstances --cli-region={region} --limit=100` |

### Count GaussDB (MySQL-compatible) Instances

| Purpose | Command |
|---------|---------|
| Count all GaussDB (MySQL) instances | `hcloud GaussDB ListGaussMySqlInstances --cli-region={region} --limit=100` |

### Count-Only Lookup (jq)

To return just the numeric count:

```bash
hcloud GaussDBforopenGauss ListInstances --cli-region={region} --limit=100 | jq -r '.total_count'
```

```bash
hcloud GaussDB ListGaussMySqlInstances --cli-region={region} --limit=100 | jq -r '.total_count'
```

### Size Lookup (jq)

To sum the storage size (GB) of all returned instances (`volume.size` may be a
number or a numeric string, so `tonumber` is applied for robustness):

```bash
hcloud GaussDBforopenGauss ListInstances --cli-region={region} --limit=100 | jq '[.instances[].volume.size // 0 | tonumber] | add // 0'
```

```bash
hcloud GaussDB ListGaussMySqlInstances --cli-region={region} --limit=100 | jq '[.instances[].volume.size // 0 | tonumber] | add // 0'
```

> Note: `volume.size` is per instance in GB. When more than 100 instances exist,
> paginate via `--offset` (in steps of 100) and sum across pages for the total size.

### SDK Fallback Examples

When the CLI is unavailable, use the Python SDK:

```python
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkgaussdbforopengauss.v3.region.gaussdbforopengauss_region import GaussDBforopenGaussRegion
from huaweicloudsdkgaussdbforopengauss.v3 import GaussDBforopenGaussClient, ListInstancesRequest

credentials = BasicCredentials().with_ak(os.getenv("HUAWEI_ACCESS_KEY")) \
                                .with_sk(os.getenv("HUAWEI_SECRET_KEY"))

client = GaussDBforopenGaussClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(GaussDBforopenGaussRegion.value_of("{region}")) \
    .build()

response = client.list_instances(ListInstancesRequest(limit=100))
print("count:", response.total_count)
print("total size (GB):", sum(i.volume.size for i in (response.instances or []) if i.volume))
```

```python
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkgaussdb.v3.region.gaussdb_region import GaussDBRegion
from huaweicloudsdkgaussdb.v3 import GaussDBClient, ListGaussMySqlInstancesRequest

credentials = BasicCredentials().with_ak(os.getenv("HUAWEI_ACCESS_KEY")) \
                                .with_sk(os.getenv("HUAWEI_SECRET_KEY"))

client = GaussDBClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(GaussDBRegion.value_of("{region}")) \
    .build()

response = client.list_gauss_my_sql_instances(ListGaussMySqlInstancesRequest(limit=100))
print("count:", response.total_count)
print("total size (GB):", sum(int(i.volume.size) for i in (response.instances or []) if i.volume))
```

A ready-to-run helper script is provided in `scripts/count_gaussdb_instances.py` covering both product families
(count + total storage size). The script catches `ClientRequestException`/`SdkException` and prints a concise,
actionable error message (credential / region / IAM-permission hint) then exits non-zero — it never dumps a raw
traceback.

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4` |
| `{limit}` | No | Max records per page (1-100, default 100); does not affect `total_count`. For total size with >100 instances, paginate via `--offset` and sum across pages | `100` |

## Reference Documents

- [CLI Installation Guide](references/cli-installation-guide.md)
- [IAM Policies](references/iam-policies.md)
- [Verification Method](references/verification-method.md)
- [Data Flow Diagram](references/dataflow-diagram.md)
- [Acceptance Criteria](references/acceptance-criteria.md)

## KooCLI Command Format Standard

```bash
hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | `GaussDBforopenGauss`, `GaussDB` | `hcloud GaussDBforopenGauss ListInstances --cli-region={region}` |
| Operation name | PascalCase | `ListInstances`, `ListGaussMySqlInstances` |
| Region parameter | `--cli-region=<value>` | `--cli-region=cn-north-4` |
| Simple parameter | `--key=value` | `--limit=100` |
