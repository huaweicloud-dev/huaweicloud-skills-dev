---
name: huawei-cloud-security-group-list
description: >-
  Lists Huawei Cloud security groups (安全组) — enumerates all security groups
  in a VPC project with security group ID, name, description, enterprise project
  ID, tags and creation time, using the KooCLI `hcloud VPC ListSecurityGroups`
  command (primary) or the huaweicloudsdkvpc Python SDK (fallback). Provides
  read-only security group inventory for network security auditing, firewall
  rule review and resource discovery.
  Use this skill whenever the user mentions security group list query.
  Triggers include: list security groups, security group list, query security
  groups, enumerate security groups, show security groups, security group
  inventory, 查询安全组, 安全组列表, 查看安全组, 列出安全组, 获取安全组列表,
  查询安全组列表.
tags:
  - huawei-cloud
  - vpc
  - security-group
  - query
  - inventory
---

# Huawei Cloud Security Group List Skill

## Overview

This skill lists all Huawei Cloud security groups owned by the authenticated account in the specified region.
It is a read-only inventory skill: it never creates, modifies, deletes security groups, or changes any firewall rule.

**Architecture:**

```
Agent → hcloud CLI (KooCLI VPC, primary) → Huawei Cloud VPC API
       ↘ huaweicloudsdkvpc Python SDK (fallback)  ↗
```

**Applicable Scenarios:**

- Security group inventory and resource discovery
- Network security auditing (reviewing existing security groups)
- Troubleshooting connectivity (checking which security groups exist)
- Compliance reporting (enumerating all security groups per project)

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **IAM permissions** — `vpc:securityGroups:list` — See `references/vpc-policies.md`
3. **Python 3.6+** with `huaweicloudsdkvpc` package (SDK fallback) — `pip install huaweicloudsdkvpc`

> **Credentials.** KooCLI reads credentials from `hcloud configure` (AK/SK) or environment variables. The VPC API is
> region-scoped: the same account credentials used for other Huawei Cloud services work here, and `--cli-region`
> selects the region whose security groups are queried. Never ask the user to paste AK/SK into the conversation.

## Workflow

1. **Verify prerequisites** — `hcloud version`, then run the list command (below)
2. **Run the query** — `hcloud VPC ListSecurityGroups --cli-region=<region>` (CLI primary) with desired options
3. **Handle results** — Parse security group IDs, names, descriptions, and tags; report the total security group count
4. **Fallback** — If the CLI is unavailable, use the Python SDK example below

## Core Commands

### List All Security Groups

```bash
hcloud VPC ListSecurityGroups --cli-region=cn-north-4
```

### List Security Groups (JSON Output)

```bash
hcloud VPC ListSecurityGroups --cli-region=cn-north-4 --cli-output=json
```

### Filter by Security Group Name

```bash
hcloud VPC ListSecurityGroups --cli-region=cn-north-4 --name.1=<sg-name>
```

### Filter by Security Group ID

```bash
hcloud VPC ListSecurityGroups --cli-region=cn-north-4 --id.1=<sg-id>
```

### Filter by Enterprise Project

```bash
hcloud VPC ListSecurityGroups --cli-region=cn-north-4 --enterprise_project_id=0
```

### Pagination (limit + marker)

```bash
hcloud VPC ListSecurityGroups --cli-region=cn-north-4 --limit=10 --marker=<last-sg-id>
```

### SDK Fallback Example

```python
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkvpc.v3 import VpcClient
from huaweicloudsdkvpc.v3.model import ListSecurityGroupsRequest
from huaweicloudsdkvpc.v3.region.vpc_region import VpcRegion

credentials = BasicCredentials(
    os.environ["HUAWEI_CLOUD_ACCESS_KEY"],
    os.environ["HUAWEI_CLOUD_SECRET_KEY"],
)
client = VpcClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(VpcRegion.value_of("cn-north-4")) \
    .build()

response = client.list_security_groups(ListSecurityGroupsRequest())
groups = response.security_groups or []
for sg in groups:
    print(sg.id, sg.name, sg.description, sg.enterprise_project_id)
print("Security group number:", len(groups))
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--cli-region` | Yes | Huawei Cloud region for the CLI endpoint | `cn-north-4` |
| `--project_id` | No | Project ID (defaults to the region's parent project) | `--project_id=xxx` |
| `--name.[N]` | No | Filter by security group name (repeatable) | `--name.1=sg-demo` |
| `--id.[N]` | No | Filter by security group ID (repeatable) | `--id.1=xxx` |
| `--description.[N]` | No | Filter by description (repeatable) | `--description.1=web` |
| `--enterprise_project_id` | No | Filter by enterprise project ID (`0` = default) | `--enterprise_project_id=0` |
| `--limit` | No | Page size, 0–2000 | `--limit=50` |
| `--marker` | No | Start resource ID for pagination | `--marker=<last-sg-id>` |
| `--cli-output` | No | Output format (json/table) | `--cli-output=json` |

## Reference Documents

- [CLI Installation Guide](references/cli-installation-guide.md)
- [VPC Policies](references/vpc-policies.md)
- [Verification Method](references/verification-method.md)
- [Data Flow Diagram](references/dataflow-diagram.md)
- [Acceptance Criteria](references/acceptance-criteria.md)

## KooCLI Command Format Standard

The `hcloud VPC` module maps directly to the Huawei Cloud VPC API operations.

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | `VPC` | `hcloud VPC ListSecurityGroups` |
| Operation name | VPC API operation name | `ListSecurityGroups` |
| Simple parameter | `--key=value` | `hcloud VPC ListSecurityGroups --name.1=web` |
| Output format | `--cli-output=json/table` | `--cli-output=json` |
| Credentials | KooCLI configured account (AK/SK or env vars) | `hcloud configure` |
