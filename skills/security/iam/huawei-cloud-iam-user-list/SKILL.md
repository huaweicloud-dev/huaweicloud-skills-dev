---
name: huawei-cloud-iam-user-list
description: >-
  Lists Huawei Cloud IAM (Identity and Access Management) users — enumerates all
  IAM users (sub-accounts) under the authenticated account with user ID, name,
  enabled status and description, using the KooCLI `hcloud IAM KeystoneListUsers`
  command (primary) or the huaweicloudsdkiam Python SDK (fallback). Provides
  read-only IAM user inventory for account management, security auditing,
  permission review and resource discovery.
  Use this skill whenever the user mentions IAM user list query.
  Triggers include: list IAM users, IAM user list, query IAM users, enumerate
  IAM users, show IAM users, IAM user inventory, sub-account list, 查询IAM用户,
  IAM用户列表, 查看IAM用户, 子账号列表, 子用户列表, 列出IAM用户, 查询子账号.
tags:
  - huawei-cloud
  - iam
  - user
  - query
  - inventory
---

# Huawei Cloud IAM User List Skill

## Overview

This skill lists all Huawei Cloud IAM (Identity and Access Management) users owned by the authenticated account.
It is a read-only inventory skill: it never creates, modifies, deletes users, or changes any IAM configuration.

**Architecture:**

```
Agent → hcloud CLI (KooCLI IAM, primary) → Huawei Cloud IAM API
       ↘ huaweicloudsdkiam Python SDK (fallback)  ↗
```

**Applicable Scenarios:**

- IAM user (sub-account) inventory and resource discovery
- Security and compliance auditing (account access review)
- Permission review (checking which sub-accounts exist)
- Troubleshooting account-level IAM configuration

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **IAM permissions** — `iam:users:listUsers` — See `references/iam-policies.md`
3. **Python 3.6+** with `huaweicloudsdkiam` package (SDK fallback) — `pip install huaweicloudsdkiam`

> **Credentials.** KooCLI reads credentials from `hcloud configure` (AK/SK) or environment variables. The IAM API is
> global (no region endpoint), so the same account credentials used for other Huawei Cloud services work here. Never
> ask the user to paste AK/SK into the conversation.

## Workflow

1. **Verify prerequisites** — `hcloud version`, then run the list command (below)
2. **Run the query** — `hcloud IAM KeystoneListUsers` (CLI primary) with desired options
3. **Handle results** — Parse user IDs, names, enabled status, and descriptions; report the total user count
4. **Fallback** — If the CLI is unavailable, use the Python SDK example below

## Core Commands

### List All IAM Users

```bash
hcloud IAM KeystoneListUsers --cli-region=cn-north-4
```

### List IAM Users (JSON Output)

```bash
hcloud IAM KeystoneListUsers --cli-region=cn-north-4 --cli-output=json
```

### Filter by User Name

```bash
hcloud IAM KeystoneListUsers --cli-region=cn-north-4 --name=<user-name>
```

### Filter by Domain ID

```bash
hcloud IAM KeystoneListUsers --cli-region=cn-north-4 --domain_id=<domain-id>
```

### SDK Fallback Example

```python
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkiam.v3 import IamClient
from huaweicloudsdkiam.v3.model import KeystoneListUsersRequest
from huaweicloudsdkiam.v3.region.iam_region import IamRegion

credentials = BasicCredentials(
    os.environ["HUAWEI_CLOUD_ACCESS_KEY"],
    os.environ["HUAWEI_CLOUD_SECRET_KEY"],
)
client = IamClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(IamRegion.value_of("cn-north-4")) \
    .build()

response = client.keystone_list_users(KeystoneListUsersRequest())
users = response.users or []
for user in users:
    print(user.id, user.name, user.enabled, user.description)
print("User number:", len(users))
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--cli-region` | Yes | Huawei Cloud region for the CLI endpoint | `cn-north-4` |
| `--name` | No | Filter by IAM user name | `--name=admin` |
| `--domain_id` | No | Filter by domain ID | `--domain_id=xxx` |
| `--enabled` | No | Filter by enabled status (true/false) | `--enabled=true` |
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
| Service name | `IAM` | `hcloud IAM KeystoneListUsers` |
| Operation name | IAM API operation name | `KeystoneListUsers` |
| Simple parameter | `--key=value` | `hcloud IAM KeystoneListUsers --name=admin` |
| Output format | `--cli-output=json/table` | `--cli-output=json` |
| Credentials | KooCLI configured account (AK/SK or env vars) | `hcloud configure` |
