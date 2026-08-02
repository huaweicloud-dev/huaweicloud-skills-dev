---
name: huawei-cloud-eip-list
description: >-
  Lists Huawei Cloud EIP (Elastic IP, 弹性公网IP) resources — enumerates all
  EIPs in a region with public IP address, EIP ID, status, bandwidth, associated
  instance and creation time, using the KooCLI `hcloud EIP ListPublicips`
  command (primary) or the huaweicloudsdkeip Python SDK (fallback). Provides
  read-only EIP inventory for network resource auditing, cost review and
  resource discovery.
  Use this skill whenever the user mentions EIP list query.
  Triggers include: list EIPs, EIP list, query EIP, enumerate EIPs, show EIPs,
  elastic IP list, public IP inventory, 查询弹性公网IP, EIP列表, 弹性公网IP列表,
  查看EIP, 列出EIP, 获取EIP列表, 查询EIP, 查询公网IP.
tags:
  - huawei-cloud
  - vpc
  - eip
  - network
  - query
  - inventory
---

# Huawei Cloud EIP List Skill

## Overview

This skill lists all Huawei Cloud EIP (Elastic IP, 弹性公网IP) resources owned by the authenticated account in the specified region.
It is a read-only inventory skill: it never creates, modifies, deletes EIPs, or changes any bandwidth or association.

**Architecture:**

```
Agent → hcloud CLI (KooCLI EIP, primary) → Huawei Cloud EIP API
       ↘ huaweicloudsdkeip Python SDK (fallback)  ↗
```

**Applicable Scenarios:**

- EIP inventory and resource discovery (which public IPs exist, their status and bandwidth)
- Network cost review (EIP count, bandwidth size and billing mode per region)
- Troubleshooting connectivity (checking whether an EIP exists and is bound to an instance)
- Compliance reporting (enumerating all EIPs per project/region)

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **IAM permissions** — `vpc:publicIps:list` (list) and `vpc:publicIps:get` (show detail) — See `references/eip-policies.md`
3. **Python 3.6+** with `huaweicloudsdkeip` package (SDK fallback) — `pip install huaweicloudsdkeip`

> **Credentials.** KooCLI reads credentials from `hcloud configure` (AK/SK) or environment variables. The EIP API is
> region-scoped: the same account credentials used for other Huawei Cloud services work here, and `--cli-region`
> selects the region whose EIPs are queried. Never ask the user to paste AK/SK into the conversation.

## Workflow

1. **Verify prerequisites** — `hcloud version`, then run the list command (below)
2. **Run the query** — `hcloud EIP ListPublicips --cli-region=<region>` (CLI primary) with desired options
3. **Handle results** — Parse EIP IDs, public IP addresses, statuses, bandwidths, and associated instances; report the total EIP count
4. **Fallback** — If the CLI is unavailable, use the Python SDK example below

## Core Commands

### List All EIPs

```bash
hcloud EIP ListPublicips --cli-region=cn-north-4
```

### List EIPs (JSON Output)

```bash
hcloud EIP ListPublicips --cli-region=cn-north-4 --cli-output=json
```

> **Note:** `ListPublicips` is a multi-version API — hcloud prints a version hint line
> (`ListPublicips is a multi-version API, where the version (v3) is default...`) to
> **stdout** before the JSON body. When piping to `jq`/`python3 -c json.load`, skip the
> first line (e.g. `tail -n +2`) or use the SDK fallback path below.

### Filter by EIP ID

```bash
hcloud EIP ListPublicips --cli-region=cn-north-4 --id.1=<eip-id>
```

### Filter by Public IP Address

```bash
hcloud EIP ListPublicips --cli-region=cn-north-4 --public_ip_address.1=<ip-address>
```

### Filter by IP Version

```bash
hcloud EIP ListPublicips --cli-region=cn-north-4 --ip_version.1=4
```

### Filter by Enterprise Project

```bash
hcloud EIP ListPublicips --cli-region=cn-north-4 --enterprise_project_id.1=0
```

### Pagination (limit + marker, v2 API)

```bash
hcloud EIP ListPublicips/v2 --cli-region=cn-north-4 --limit=10 --marker=<last-eip-id>
```

### Show EIP Detail

```bash
hcloud EIP ShowPublicip/v3 --cli-region=cn-north-4 --publicip_id=<eip-id>
```

### SDK Fallback Example

```python
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkeip.v2 import EipClient
from huaweicloudsdkeip.v2.model import ListPublicipsRequest
from huaweicloudsdkeip.v2.region.eip_region import EipRegion

credentials = BasicCredentials(
    os.environ["HUAWEI_CLOUD_ACCESS_KEY"],
    os.environ["HUAWEI_CLOUD_SECRET_KEY"],
)
client = EipClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(EipRegion.value_of("cn-north-4")) \
    .build()

response = client.list_publicips(ListPublicipsRequest())
eips = response.publicips or []
for eip in eips:
    print(eip.id, eip.public_ip_address, eip.status, eip.bandwidth)
print("EIP number:", len(eips))
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--cli-region` | Yes | Huawei Cloud region for the CLI endpoint | `cn-north-4` |
| `--project_id` | No | Project ID (defaults to the region's parent project) | `--project_id=xxx` |
| `--id.[N]` | No | Filter by EIP ID (repeatable) | `--id.1=xxx` |
| `--public_ip_address.[N]` | No | Filter by public IP address (repeatable) | `--public_ip_address.1=1.2.3.4` |
| `--ip_version.[N]` | No | Filter by IP version (`4` or `6`) | `--ip_version.1=4` |
| `--enterprise_project_id.[N]` | No | Filter by enterprise project ID (`0` = default) | `--enterprise_project_id.1=0` |
| `--status.[N]` | No | Filter by EIP status (v3 API) | `--status.1=ACTIVE` |
| `--limit` | No | Page size (v2 API, up to 100) | `--limit=50` |
| `--marker` | No | Start resource ID for pagination (v2 API) | `--marker=<last-eip-id>` |
| `--cli-output` | No | Output format (json/table) | `--cli-output=json` |

## Reference Documents

- [CLI Installation Guide](references/cli-installation-guide.md)
- [EIP Policies](references/eip-policies.md)
- [Verification Method](references/verification-method.md)
- [Data Flow Diagram](references/dataflow-diagram.md)
- [Acceptance Criteria](references/acceptance-criteria.md)

## KooCLI Command Format Standard

The `hcloud EIP` module maps directly to the Huawei Cloud EIP API operations.

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | `EIP` | `hcloud EIP ListPublicips` |
| Operation name | EIP API operation name | `ListPublicips` |
| Simple parameter | `--key=value` | `hcloud EIP ListPublicips --cli-output=json` |
| Output format | `--cli-output=json/table` | `--cli-output=json` |
| Credentials | KooCLI configured account (AK/SK or env vars) | `hcloud configure` |
