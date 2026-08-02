---
name: huawei-cloud-ecs-eip-query
description: >-
  Queries the EIP (Elastic IP, 弹性公网IP) bound to a single Huawei Cloud ECS
  instance — given an ECS ID or ECS name, returns the associated public IP
  address, EIP ID, status, bandwidth and binding details, using the KooCLI
  `hcloud EIP ListPublicips` command (primary, filtered by `vnic.device_id`)
  or the huaweicloudsdkeip Python SDK (fallback). Provides a read-only
  per-instance EIP lookup for network troubleshooting, cost review and
  resource discovery.
  Use this skill whenever the user wants the EIP of a specific ECS.
  Triggers include: ECS EIP query, EIP of ECS, find ECS public IP, ECS 的EIP,
  查询ECS的弹性公网IP, ECS公网IP, ECS绑定的EIP, 单个ECS的eip, 查询ECS的eip,
  查看ECS的弹性IP, ECS外网IP, 获取ECS公网地址.
tags:
  - huawei-cloud
  - ecs
  - eip
  - vpc
  - network
  - query
---

# Huawei Cloud ECS EIP Query Skill

## Overview

This skill queries the EIP (Elastic IP, 弹性公网IP) bound to a **single** Huawei Cloud ECS instance.
Given an ECS ID or ECS name (and an optional region), it returns the associated public IP address, EIP ID,
status, bandwidth, and binding metadata. It is a read-only lookup skill: it never creates, modifies or
deletes EIPs or ECS instances.

**Architecture:**

```
Agent → hcloud CLI (EIP, primary) → Huawei Cloud EIP API
       ↘ huaweicloudsdkeip Python SDK (fallback)  ↗
```

**Applicable Scenarios:**

- Check which public IP a specific ECS is using (troubleshooting connectivity)
- Per-instance network cost review (EIP bandwidth and billing mode)
- Resource discovery and inventory (mapping ECS → EIP bindings)
- Compliance reporting (per-instance public exposure)

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **IAM permissions** — `vpc:publicIps:list` (list) and `vpc:publicIps:get` (show detail), plus `ecs:servers:list` / `ecs:servers:get` when resolving an ECS by name — See `references/eip-policies.md`
3. **Python 3.6+** with `huaweicloudsdkeip` package (SDK fallback) — `pip install huaweicloudsdkeip`

> **Credentials.** KooCLI reads credentials from `hcloud configure` (AK/SK) or environment variables. The EIP API is
> region-scoped: the same account credentials used for other Huawei Cloud services work here, and `--cli-region`
> selects the region whose EIPs are queried. Never ask the user to paste AK/SK into the conversation.

## Workflow

1. **Determine the ECS** — accept the ECS ID directly, or resolve an ECS name to its ID first:
   `hcloud ECS ListServersDetails --cli-region=<region> --name=<ecs-name>`
2. **Run the query** — `hcloud EIP ListPublicips/v3 --cli-region=<region> --vnic.device_id.1=<ecs-id>` (CLI primary)
3. **Handle results** — Parse the EIP public IP, EIP ID, status, bandwidth and binding details; report whether the ECS has a bound EIP
4. **Fallback** — If the CLI is unavailable, use the Python SDK example below

## Core Commands

### Query EIP by ECS ID (primary)

```bash
hcloud EIP ListPublicips/v3 --cli-region=cn-north-4 --vnic.device_id.1=<ecs-id>
```

`vnic.device_id` is the bound ECS instance ID — this returns only the EIPs bound to that ECS.

### Query EIP by ECS ID (JSON Output)

```bash
hcloud EIP ListPublicips/v3 --cli-region=cn-north-4 --vnic.device_id.1=<ecs-id> --cli-output=json
```

> **Note:** `ListPublicips` is a multi-version API — the version hint line
> (`ListPublicips is a multi-version API, where the version (v3) is default...`) is
> printed to **stdout** only when the `/v3` version suffix is **omitted**. All commands
> in this skill use the explicit `/v3` suffix, so their output is **pure JSON** — parse
> it directly with `jq`/`python3 -c json.load` (do **not** use `tail -n +2`, which would
> cut off the first `{` and break JSON parsing). If you ever run a command without the
> version suffix and see the hint line, drop it with `tail -n +2` before parsing, or
> prefer the SDK fallback path below.

### Resolve ECS Name to ID

```bash
hcloud ECS ListServersDetails --cli-region=cn-north-4 --name=<ecs-name> --cli-output=json
```

The ECS ID is in the `servers[].id` field. ECS names are fuzzy matched; pass the exact name for a precise lookup.

### Show ECS Detail (addresses include the public IP)

```bash
hcloud ECS ShowServer --cli-region=cn-north-4 --server_id=<ecs-id>
```

The `addresses` field lists both fixed (private) and floating (public/EIP) addresses with `OS-EXT-IPS:type` of `fixed` or `floating`.

### Show EIP Detail

```bash
hcloud EIP ShowPublicip/v3 --cli-region=cn-north-4 --publicip_id=<eip-id>
```

### SDK Fallback Example

```python
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkeip.v3 import EipClient
from huaweicloudsdkeip.v3.model import ListPublicipsRequest
from huaweicloudsdkeip.v3.region.eip_region import EipRegion

credentials = BasicCredentials(
    os.environ["HUAWEI_CLOUD_ACCESS_KEY"],
    os.environ["HUAWEI_CLOUD_SECRET_KEY"],
)
client = EipClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(EipRegion.value_of("cn-north-4")) \
    .build()

request = ListPublicipsRequest()
request.vnic_device_id = ["<ecs-id>"]
response = client.list_publicips(request)
eips = response.publicips or []
for eip in eips:
    print(eip.id, eip.public_ip_address, eip.status, eip.associate_instance_type)
print("EIP number:", len(eips))
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--cli-region` | Yes | Huawei Cloud region for the CLI endpoint | `cn-north-4` |
| `--vnic.device_id.[N]` | Yes (or ECS name + `ListServersDetails`) | Filter by bound ECS instance ID | `--vnic.device_id.1=xxx` |
| `--project_id` | No | Project ID (defaults to the region's parent project) | `--project_id=xxx` |
| `--name` | No* | ECS name to resolve to an ECS ID first | `--name=my-ecs` |
| `--server_id` | No* | ECS ID for `ECS ShowServer` detail lookup | `--server_id=xxx` |
| `--publicip_id` | No* | EIP ID for `EIP ShowPublicip/v3` detail lookup | `--publicip_id=xxx` |
| `--cli-output` | No | Output format (json/table) | `--cli-output=json` |

\* Used by the corresponding sub-command; the primary EIP query only needs the ECS ID and region.

## Reference Documents

- [CLI Installation Guide](references/cli-installation-guide.md)
- [EIP and ECS Policies](references/eip-policies.md)
- [Verification Method](references/verification-method.md)
- [Data Flow Diagram](references/dataflow-diagram.md)
- [Acceptance Criteria](references/acceptance-criteria.md)

## KooCLI Command Format Standard

The `hcloud EIP` and `hcloud ECS` modules map directly to the Huawei Cloud EIP/ECS API operations.

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | `EIP` / `ECS` | `hcloud EIP ListPublicips` |
| Operation name | EIP/ECS API operation name | `ListPublicips` / `ShowServer` |
| Simple parameter | `--key=value` | `hcloud EIP ListPublicips --cli-output=json` |
| Array parameter | `--key.[N]=value` | `--vnic.device_id.1=<ecs-id>` |
| Output format | `--cli-output=json/table` | `--cli-output=json` |
| Credentials | KooCLI configured account (AK/SK or env vars) | `hcloud configure` |
