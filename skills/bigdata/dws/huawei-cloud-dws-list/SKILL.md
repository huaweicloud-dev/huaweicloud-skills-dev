---
name: huawei-cloud-dws-list
description: |
  List DWS (Data Warehouse Service) clusters under a Huawei Cloud tenant and return only the cluster names.
  Based on KooCLI (hcloud) DWS ListClusters API. Useful for daily inspection, resource inventory, and quick cluster overview.
  Triggers include: "查询DWS列表", "DWS集群列表", "列出DWS", "DWS集群名称", "list DWS clusters", "DWS cluster list", "show DWS names", "DWS inventory"
tags: [huawei-cloud, dws, list, query, inventory]

# ============================================================
# Internal extension fields
# ============================================================
trigger:
  keywords: ["DWS列表", "DWS集群列表", "查询DWS", "列出DWS", "DWS集群名称", "DWS cluster list", "list DWS", "DWS names", "DWS inventory", "DWS集群"]
  resource_types: ["DWS::cluster"]
  hypotheses: ["list_clusters"]

input_schema:
  required:
    - name: "region"
      type: "string"
      description: "Huawei Cloud region identifier, used for hcloud --cli-region parameter (e.g. cn-north-4)"
  optional:
    - name: "enterprise_project_id"
      type: "string"
      description: "Enterprise project ID. If specified, only clusters bound to this enterprise project are returned; use all_granted_eps to query all authorized enterprise projects"

output_schema:
  - name: "cluster_names"
    type: "array[string]"
    description: "List of DWS cluster names under the tenant"
  - name: "count"
    type: "integer"
    description: "Total number of DWS clusters"
---

# Huawei Cloud DWS Cluster List Skill

## Overview

This skill queries the DWS (Data Warehouse Service) cluster list under a Huawei Cloud tenant and returns **only the cluster names**.
It is designed for daily inspection, resource inventory, and quick cluster overview scenarios.

**Architecture**: KooCLI (hcloud) → DWS ListClusters API → jq extraction of `clusters[].name`

**Applicable Scenarios**:

- Daily inspection of DWS clusters
- Resource inventory / asset overview
- Quick listing of all DWS cluster names under the tenant

**Typical Use Cases**:

- "查询一下我账号下有哪些DWS集群"
- "列出所有DWS集群的名称"
- "帮我看看租户下DWS列表"
- "List all my DWS clusters"
- "Show me the DWS cluster names under this tenant"

## Prerequisites

### 1. CLI Requirements

- KooCLI (hcloud) >= 3.2.0
- Verify installation: hcloud version
- If not installed or version too low, see [CLI Installation Guide](references/cli-installation-guide.md)

### 2. Authentication Configuration

- Valid Huawei Cloud credentials (AK/SK mode), configured via the hcloud configure command
- **Security Rules**:
  - Never expose AK/SK values in conversations or commands
  - Never ask users to input AK/SK directly in conversation
  - Only use the hcloud configure list command to check credential status

### 3. IAM Permission Requirements

- `dws:cluster:list` (DWS cluster list permission)
- See [IAM Policies](references/iam-policies.md)

## Workflow

1. Confirm the target region (default `cn-north-4` if not specified).
2. Run the `hcloud DWS ListClusters` command with `--cli-region=<region>`.
3. Optionally filter by enterprise project with `--enterprise_project_id=<ep_id>`.
4. Extract cluster names from the JSON response with `jq -r '.clusters[]?.name'`.
5. Output the cluster name list; if none exist, report "No DWS clusters found in region <region>".

## Core Commands

```bash
# List all DWS clusters and extract cluster names
hcloud DWS ListClusters --cli-region=<region> | jq -r '.clusters[]?.name'

# List DWS clusters under a specific enterprise project
hcloud DWS ListClusters --cli-region=<region> --enterprise_project_id=<ep_id> | jq -r '.clusters[]?.name'

# List clusters across all granted enterprise projects
hcloud DWS ListClusters --cli-region=<region> --enterprise_project_id=all_granted_eps | jq -r '.clusters[]?.name'

# Full JSON output (when cluster details are also needed)
hcloud DWS ListClusters --cli-region=<region>
```

### Script Mode (quality-reporting integrated)

```bash
# Query DWS cluster names with execution-quality reporting (skill_quality_sdk)
python3 scripts/list_dws_clusters.py --region <region> [--enterprise_project_id <ep_id>]
```

The wrapper script `scripts/list_dws_clusters.py` runs the same hcloud command, extracts cluster names,
and reports execution quality (success/biz_fail/sys_fail + error codes) to the skillsopr operations console
via the vendored `scripts/skill_quality_sdk.py`. Reporting is silent on failure and never blocks the query.

## Error Handling

> **Important**: hcloud outputs **non-JSON error text to stdout with exit code 0** for parameter/credential errors
> (invalid region, bad AK/SK, etc.). Do NOT rely on the shell exit code alone.

| Error scenario | hcloud behavior | Recommended handling |
|----------------|-----------------|----------------------|
| Invalid `--cli-region` | stdout contains `[USE_ERROR]The value of cli-region is not supported...` + supported region list, exit 0 | Use the wrapper script (`scripts/list_dws_clusters.py`) which detects `[USE_ERROR]` / `Failed to obtain project ID` / `Unauthorized` markers regardless of exit code and reports the real cause; or run the bare `hcloud` command first to confirm the output is valid JSON before piping to `jq` |
| Invalid / expired AK/SK | stdout contains `Failed to obtain project ID... Unauthorized`, exit 0 | Wrapper reports "凭证认证失败" with guidance to check credential status via the hcloud configure list command and IAM `dws:cluster:list` permission |
| Network timeout | non-zero exit code | Wrapper reports network/timeout error (N01) |

The wrapper (`_run_hcloud`) checks hcloud output for `[USE_ERROR]`, `[OPENAPI_ERROR]`, `Failed to obtain project ID`,
`error_code` and `Unauthorized` markers **before** checking the exit code, then raises an exception that carries
both a translated fix hint and the raw hcloud output — so the real reason is never masked by a JSON parse fallback.

**Response format** (JSON):

```json
{
  "clusters": [
    {"id": "xxx", "name": "cluster-1", "status": "AVAILABLE"},
    {"id": "yyy", "name": "cluster-2", "status": "ACTIVE"}
  ],
  "count": 2
}
```

Cluster names are extracted via `jq -r '.clusters[]?.name'`. When no clusters exist, the API returns `{"clusters": [], "count": 0}` and the skill reports "No DWS clusters found".

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `region` | Yes | Huawei Cloud region for `--cli-region` | `cn-north-4` |
| `enterprise_project_id` | No | Enterprise project ID filter; `all_granted_eps` queries all authorized enterprise projects | `all_granted_eps` |

## KooCLI Command Format Standard

```bash
hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | Exact KooCLI Service name beginning with uppercase | `DWS` |
| Operation name | PascalCase | `ListClusters` |
| Region parameter | `--cli-region=<value>` | `--cli-region=cn-north-4` |
| Simple parameter | `--key=value` | `--enterprise_project_id=all_granted_eps` |

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Least-privilege IAM policy for DWS cluster listing
- [CLI Installation Guide](references/cli-installation-guide.md) — KooCLI installation and configuration
- [Verification Method](references/verification-method.md) — How to verify the skill works
- [Data Flow Diagram](references/dataflow-diagram.md) — Mermaid diagram of the query flow
- [Acceptance Criteria](references/acceptance-criteria.md) — Definition of done for this skill
