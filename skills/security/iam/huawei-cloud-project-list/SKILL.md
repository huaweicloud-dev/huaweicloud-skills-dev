---
name: huawei-cloud-project-list
description: >-
  Lists Huawei Cloud IAM (Identity and Access Management) projects — enumerates
  all projects under the authenticated account with project ID, name, domain ID,
  parent ID, enabled status and description, using the KooCLI `hcloud IAM
  KeystoneListProjects` command (primary) or the huaweicloudsdkiam Python SDK
  (fallback). Provides read-only project inventory for account management,
  resource discovery, permission review and multi-region operations planning.
  Use this skill whenever the user mentions project list query.
  Triggers include: list projects, project list, query projects, enumerate
  projects, show projects, project inventory, 查询项目, 项目列表, 查看项目,
  列出项目, 获取项目列表, 华为云项目, 查询华为云项目列表.
tags:
  - huawei-cloud
  - iam
  - project
  - query
  - inventory
---

# Huawei Cloud Project List Skill

## Overview

This skill lists all Huawei Cloud IAM (Identity and Access Management) projects owned by the authenticated account.
It is a read-only inventory skill: it never creates, modifies, deletes projects, or changes any IAM configuration.

**Architecture:**

```
Agent → hcloud CLI (KooCLI IAM, primary) → Huawei Cloud IAM API
       ↘ huaweicloudsdkiam Python SDK (fallback)  ↗
```

**Applicable Scenarios:**

- Project inventory and resource discovery (locate project IDs for other services)
- Multi-region operations planning (each region has its own system project)
- Permission review (checking which projects exist under the account)
- Troubleshooting account-level IAM configuration

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **IAM permissions** — `iam:projects:listProjects` — See `references/iam-policies.md`
3. **Python 3.6+** with `huaweicloudsdkiam` package (SDK fallback) — `pip install huaweicloudsdkiam`

> **Credentials.** KooCLI reads credentials from `hcloud configure` (AK/SK) or environment variables. The IAM API is
> global (no region endpoint), so the same account credentials used for other Huawei Cloud services work here. Never
> ask the user to paste AK/SK into the conversation.

## Workflow

1. **Verify prerequisites** — `hcloud version`, then run the list command (below)
2. **Run the query** — `hcloud IAM KeystoneListProjects` (CLI primary) with desired options
3. **Handle results** — Parse project IDs, names, domain IDs, parent IDs, enabled status, and descriptions; report the total project count
4. **Fallback** — If the CLI is unavailable, use the Python SDK example below

## Core Commands

### List All Projects

```bash
hcloud IAM KeystoneListProjects --cli-region=cn-north-4
```

### List Projects (JSON Output)

```bash
hcloud IAM KeystoneListProjects --cli-region=cn-north-4 --cli-output=json
```

### Filter by Project Name

```bash
hcloud IAM KeystoneListProjects --cli-region=cn-north-4 --name=<project-name>
```

### Filter by Domain ID (Account ID)

```bash
hcloud IAM KeystoneListProjects --cli-region=cn-north-4 --domain_id=<domain-id>
```

### Filter by Enabled Status

```bash
hcloud IAM KeystoneListProjects --cli-region=cn-north-4 --enabled=true
```

### Filter by Parent Project ID

```bash
hcloud IAM KeystoneListProjects --cli-region=cn-north-4 --parent_id=<project-id>
```

### Pagination

```bash
hcloud IAM KeystoneListProjects --cli-region=cn-north-4 --page=1 --per_page=50
```

### SDK Fallback Example

```python
import os
from huaweicloudsdkcore.auth.credentials import GlobalCredentials
from huaweicloudsdkiam.v3 import IamClient
from huaweicloudsdkiam.v3.model import KeystoneListProjectsRequest
from huaweicloudsdkiam.v3.region.iam_region import IamRegion

# Project listing is a domain-level (global) operation, so use GlobalCredentials
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

response = client.keystone_list_projects(KeystoneListProjectsRequest())
projects = response.projects or []
for project in projects:
    print(project.id, project.name, project.domain_id, project.parent_id, project.enabled, project.description)
print("Project number:", len(projects))
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--cli-region` | Yes | Huawei Cloud region for the CLI endpoint | `cn-north-4` |
| `--name` | No | Filter by project name | `--name=cn-north-4` |
| `--domain_id` | No | Filter by domain ID (account ID) | `--domain_id=xxx` |
| `--enabled` | No | Filter by enabled status (true/false) | `--enabled=true` |
| `--parent_id` | No | Filter by parent project ID (subprojects) | `--parent_id=xxx` |
| `--page` / `--per_page` | No | Pagination (page ≥ 1, per_page 1–5000, used together) | `--page=1 --per_page=50` |
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
| Service name | `IAM` | `hcloud IAM KeystoneListProjects` |
| Operation name | IAM API operation name | `KeystoneListProjects` |
| Simple parameter | `--key=value` | `hcloud IAM KeystoneListProjects --name=cn-north-4` |
| Output format | `--cli-output=json/table` | `--cli-output=json` |
| Credentials | KooCLI configured account (AK/SK or env vars) | `hcloud configure` |
