---
name: huawei-cloud-iam-role-list
description: >-
  Lists Huawei Cloud IAM (Identity and Access Management) roles — enumerates all
  IAM roles (permissions) under the authenticated account with role ID, display
  name, internal name, catalog and type, using the KooCLI `hcloud IAM
  KeystoneListPermissions` command (primary) or the `ListPoliciesV5` command /
  huaweicloudsdkiam Python SDK (fallback). Provides read-only IAM role inventory
  for account management, security auditing, permission review and resource
  discovery.
  Use this skill whenever the user mentions IAM role list query.
  Triggers include: list IAM roles, IAM role list, query IAM roles, enumerate
  IAM roles, show IAM roles, IAM role inventory, permission list, 查询IAM角色,
  IAM角色列表, 查看IAM角色, 角色列表, 权限列表, 列出IAM角色, 查询角色, 获取角色列表.
tags:
  - huawei-cloud
  - iam
  - role
  - query
  - inventory
---

# Huawei Cloud IAM Role List Skill

## Overview

This skill lists all Huawei Cloud IAM (Identity and Access Management) roles owned by the authenticated account.
It is a read-only inventory skill: it never creates, modifies, deletes roles, or changes any IAM configuration.

**Architecture:**

```
Agent → hcloud CLI (KooCLI IAM, primary) → Huawei Cloud IAM API
       ↘ ListPoliciesV5 / huaweicloudsdkiam Python SDK (fallback)  ↗
```

**Applicable Scenarios:**

- IAM role (permission) inventory and resource discovery
- Security and compliance auditing (account access review)
- Permission review (checking which roles exist and their scope)
- Troubleshooting account-level IAM configuration

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **IAM permissions** — `iam:roles:listRoles` — See `references/iam-policies.md`
3. **Python 3.6+** with `huaweicloudsdkiam` package (SDK fallback) — `pip install huaweicloudsdkiam`

> **Credentials.** KooCLI reads credentials from `hcloud configure` (AK/SK) or environment variables. The IAM API is
> global (no region endpoint), so the same account credentials used for other Huawei Cloud services work here. Never
> ask the user to paste AK/SK into the conversation.

## Workflow

1. **Verify prerequisites** — `hcloud version`, then run the list command (below)
2. **Run the query** — `hcloud IAM KeystoneListPermissions` (CLI primary) with desired options
3. **Handle results** — Parse role IDs, display names, internal names, catalogs, and types; report the total role count
4. **Fallback** — If the CLI is unavailable, use `hcloud IAM ListPoliciesV5` or the Python SDK example below

## Core Commands

### List All IAM Roles (Permissions)

```bash
hcloud IAM KeystoneListPermissions --cli-region=cn-north-4
```

### List IAM Roles (JSON Output)

```bash
hcloud IAM KeystoneListPermissions --cli-region=cn-north-4 --cli-output=json
```

### List System-Defined Roles Only

```bash
hcloud IAM KeystoneListPermissions --cli-region=cn-north-4 --permission_type=role
```

### List System-Defined Policies Only

```bash
hcloud IAM KeystoneListPermissions --cli-region=cn-north-4 --permission_type=policy
```

### List Custom (Account) Policies

```bash
hcloud IAM KeystoneListPermissions --cli-region=cn-north-4 --domain_id=<domain-id>
```

### Filter by Service Catalog

```bash
hcloud IAM KeystoneListPermissions --cli-region=cn-north-4 --permission_type=role --catalog=CCE
```

### Filter by Display Name

```bash
hcloud IAM KeystoneListPermissions --cli-region=cn-north-4 --display_name=<display-name>
```

### v5 API Fallback (Identity Policies)

```bash
hcloud IAM ListPoliciesV5 --cli-region=cn-north-4 --policy_type=system
```

### SDK Fallback Example

```python
import os
from huaweicloudsdkcore.auth.credentials import GlobalCredentials
from huaweicloudsdkiam.v3 import IamClient
from huaweicloudsdkiam.v3.model import KeystoneListPermissionsRequest
from huaweicloudsdkiam.v3.region.iam_region import IamRegion

# IAM role listing is a domain-level (global) operation, so use GlobalCredentials
# with the domain ID (account ID). Obtain the domain ID from the console or via
# `hcloud IAM KeystoneListAuthDomains`.
credentials = GlobalCredentials(
    os.environ["HUAWEI_CLOUD_ACCESS_KEY"],
    os.environ["HUAWEI_CLOUD_SECRET_KEY"],
).with_domain_id(os.environ["HUAWEI_CLOUD_DOMAIN_ID"])

client = IamClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(IamRegion.value_of("cn-north-4")) \
    .build()

response = client.keystone_list_permissions(KeystoneListPermissionsRequest())
roles = response.roles or []
for role in roles:
    print(role.id, role.display_name, role.name, role.catalog, role.type)
print("Role number:", len(roles))
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--cli-region` | Yes | Huawei Cloud region for the CLI endpoint | `cn-north-4` |
| `--permission_type` | No | System permission type (`role` or `policy`, valid when `domain_id` is blank) | `--permission_type=role` |
| `--domain_id` | No | Account ID; if specified, only custom policies of the account are returned | `--domain_id=xxx` |
| `--catalog` | No | Service catalog of the permission (e.g. `CCE`, `ECS`) | `--catalog=CCE` |
| `--display_name` | No | Permission display name (e.g. `Administrator`) | `--display_name=ECS Administrator` |
| `--name` | No | Internal permission name | `--name=cce_adm` |
| `--type` | No | Display mode: `domain`, `project`, or `all` | `--type=domain` |
| `--page` / `--per_page` | No | Pagination for custom policies (1–300 per page) | `--page=1 --per_page=50` |
| `--cli-output` | No | Output format (json/table) | `--cli-output=json` |

## Reference Documents

- [CLI Installation Guide](references/cli-installation-guide.md)
- [IAM Policies](references/iam-policies.md)
- [Verification Method](references/verification-method.md)
- [Data Flow Diagram](references/dataflow-diagram.md)
- [Acceptance Criteria](references/acceptance-criteria.md)

## KooCLI Command Format Standard

The `hcloud IAM` module maps directly to the Huawei Cloud IAM API operations.

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | `IAM` | `hcloud IAM KeystoneListPermissions` |
| Operation name | IAM API operation name | `KeystoneListPermissions` |
| Simple parameter | `--key=value` | `hcloud IAM KeystoneListPermissions --permission_type=role` |
| Output format | `--cli-output=json/table` | `--cli-output=json` |
| Credentials | KooCLI configured account (AK/SK or env vars) | `hcloud configure` |
