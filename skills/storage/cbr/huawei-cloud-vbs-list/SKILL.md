---
name: huawei-cloud-vbs-list
description: |
  Query the current Huawei Cloud backup (VBS/Volume Backup Service) list. Lists all backups in the user's project, with optional filtering by status, name, resource type, vault, and time range. The legacy VBS service has been superseded by CBR (Cloud Backup and Recovery), so this skill queries backups through the CBR ListBackups API/CLI.
  Use when the user wants to: (1) list all backups / VBS backup list, (2) check backup status and details, (3) filter backups by name, status, resource type, vault, or time range, (4) inspect backup inventory for daily inspection or troubleshooting.
  Triggers include: "VBS", "备份列表", "备份", "云硬盘备份", "backup list", "list backups", "备份状态", "CBR", "Cloud Backup", "vbs list"
tags: ["huawei-cloud", "vbs", "cbr", "backup", "backup-list"]
---

# Huawei Cloud VBS Backup List Skill

## Overview

Query the current user's backup (VBS / Volume Backup Service) list on Huawei Cloud.

> **Note on VBS → CBR migration:** The VBS (Volume Backup Service) has been integrated into CBR
> (Cloud Backup and Recovery). All backups created under VBS are now managed and queryable through
> CBR. This skill therefore uses the CBR `ListBackups` operation (`GET /v3/{project_id}/backups`) to
> list backups, which is the successor of the legacy VBS list-backups API.

This skill provides:

- List all backups in the current project
- Filter by status, name, resource type, vault ID, AZ, resource ID, time range, etc.
- Summarize key fields (ID, name, status, resource type, created time, vault)
- CLI-first execution with SDK fallback

## Architecture

```
Huawei Cloud VBS/CBR Backup List
└── ListBackups  (GET /v3/{project_id}/backups)
    ├── CLI:  hcloud CBR ListBackups --cli-region=<region> [--param=value...]
    └── SDK:  huaweicloudsdkcbr.v1.CbrClient.list_backups(ListBackupsRequest)
```

## Prerequisites

> **Prerequisite check: Huawei Cloud CLI (hcloud / KooCLI) >= 3.2.0 required**
> Check the CLI version (run hcloud with the `version` argument) and confirm a
> version string is printed. If not installed or too old, see
> [references/cli-installation-guide.md](references/cli-installation-guide.md).

> **Prerequisite check: Huawei Cloud credentials required**
> Check the CLI profile (run hcloud with the `configure list` arguments) and
> confirm a profile with valid AK/SK exists. Credentials must be read from the
> configured CLI profile or environment variables. Never ask for or echo AK/SK
> values in the conversation.

## IAM Permission Policies

The IAM user must be granted the CBR read permission. See [references/iam-policies.md](references/iam-policies.md).

**Minimum required permissions:**

- `cbr:backups:list` — List backups

## Core Workflows

### Task 1: List All Backups

Query the full backup list of the current project/region.

```bash
hcloud CBR ListBackups --cli-region={region} --limit=50
```

### Task 2: Filter Backups

Apply one or more query filters to narrow down the result.

```bash
# By status
hcloud CBR ListBackups --cli-region={region} --status=available

# By name (fuzzy match)
hcloud CBR ListBackups --cli-region={region} --name=backup_for_image

# By resource type
hcloud CBR ListBackups --cli-region={region} --resource_type=OS::Nova::Server

# By vault
hcloud CBR ListBackups --cli-region={region} --vault_id={vault_id}

# By time range (format %YYYY-%mm-%ddT%HH:%MM:%SSZ)
hcloud CBR ListBackups --cli-region={region} --start_time=2026-01-01T00:00:00Z --end_time=2026-12-31T23:59:59Z
```

### Task 3: Paginated / Summarized Output

Pagination and summary of key backup attributes.

```bash
# Pagination
hcloud CBR ListBackups --cli-region={region} --limit=10 --offset=10

# Full JSON output (for agent consumption / parsing)
hcloud CBR ListBackups --cli-region={region} --limit=50 --cli-output=json
```

## Core Commands

| Command | Description |
|---------|-------------|
| `hcloud CBR ListBackups --cli-region={region} --limit=50` | List all backups in the project |
| `hcloud CBR ListBackups --cli-region={region} --status=available` | Filter by status |
| `hcloud CBR ListBackups --cli-region={region} --name={name}` | Filter by backup name |
| `hcloud CBR ListBackups --cli-region={region} --resource_type=OS::Nova::Server` | Filter by resource type |
| `hcloud CBR ListBackups --cli-region={region} --vault_id={vault_id}` | Filter by vault ID |
| `hcloud CBR ListBackups --cli-region={region} --start_time=... --end_time=...` | Filter by time range |
| `python3 scripts/list_vbs_backups.py --region {region} [--status ...] [--name ...] [--resource-type ...] [--vault-id ...] [--limit N]` | SDK-based listing with summarized table output |

> **KooCLI parameter format:** all parameters use the `--param=value` (equals-sign) format.

> **Status values:** `available`, `protecting`, `deleting`, `restoring`, `error`, `waiting_protect`, `waiting_delete`, `waiting_restore`.

> **Resource types:** `OS::Cinder::Volume` (云硬盘), `OS::Nova::Server` (云服务器).

## Script Tools

### `scripts/list_vbs_backups.py` — SDK-based backup listing with summary

Reads AK/SK from `HUAWEICLOUD_SDK_AK` / `HUAWEICLOUD_SDK_SK` environment variables (or `HUAWEI_ACCESS_KEY` / `HUAWEI_SECRET_KEY`), lists backups via the CBR SDK, and prints a concise summary table.

```bash
# List all backups (first page)
python3 scripts/list_vbs_backups.py --region cn-north-4

# Filter by status
python3 scripts/list_vbs_backups.py --region cn-north-4 --status available

# Filter by name / resource type / vault
python3 scripts/list_vbs_backups.py --region cn-north-4 --name backup_for_image --resource-type OS::Nova::Server --vault-id bf33d48b-...

# Control page size
python3 scripts/list_vbs_backups.py --region cn-north-4 --limit 20 --offset 0
```

## Parameter Confirmation

> **Before executing any task, confirm the following parameters with the user. Guessing is prohibited.**

> **Two parameter conventions — do not mix:**
>
> - **CLI (hcloud):** KooCLI parameters use underscores and the `--param=value` form, e.g.
>   `--resource_type=OS::Nova::Server`, `--vault_id=<id>`, `--start_time=...`.
> - **SDK script (`scripts/list_vbs_backups.py`):** the script's argparse interface uses hyphens, e.g.
>   `--resource-type OS::Nova::Server`, `--vault-id <id>`, `--start-time ...`. Using the underscore
>   form against the script raises `unrecognized arguments`.

| Parameter | Required/Optional | Description | Default |
|-----------|------------------|-------------|---------|
| `{region}` | Required | Huawei Cloud region (e.g., `cn-north-4`); must be provided or resolved from the profile | - |
| `--status` | Optional | Filter by backup status | - |
| `--name` | Optional | Filter by backup name (fuzzy) | - |
| `--resource_type` (CLI) / `--resource-type` (script) | Optional | Filter by resource type (`OS::Cinder::Volume` / `OS::Nova::Server`) | - |
| `--vault_id` (CLI) / `--vault-id` (script) | Optional | Filter by vault ID | - |
| `--start_time` / `--end_time` (CLI) / `--start-time` / `--end-time` (script) | Optional | Time range filter in `%YYYY-%mm-%ddT%HH:%MM:%SSZ` format | - |
| `--limit` | Optional | Page size | 50 |
| `--offset` | Optional | Page offset | 0 |

## KooCLI Command Format Standard

```bash
hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | Exact KooCLI Service name beginning with uppercase/title case | `CBR` |
| Operation name | PascalCase | `ListBackups` |
| Region parameter | `--cli-region=<value>` | `--cli-region=cn-north-4` |
| Simple parameter | `--key=value` | `--status=available` |

All concrete commands must use the `--param=value` equals-sign format.

## Verification Method

See [references/verification-method.md](references/verification-method.md) for details.

**Quick validation:**

```bash
# Confirm CLI works (returns backup list or empty array)
hcloud CBR ListBackups --cli-region=cn-north-4 --limit=1

# Confirm SDK script works
python3 scripts/list_vbs_backups.py --region cn-north-4 --limit=5
```

## Reference Documents

| Document | Description |
|----------|-------------|
| [references/iam-policies.md](references/iam-policies.md) | Least-privilege IAM policy for listing backups |
| [references/verification-method.md](references/verification-method.md) | Verification steps and sample outputs |
| [references/dataflow-diagram.md](references/dataflow-diagram.md) | Mermaid data flow diagram |
| [references/acceptance-criteria.md](references/acceptance-criteria.md) | Acceptance criteria |
| [references/cli-installation-guide.md](references/cli-installation-guide.md) | CLI installation and authentication guide |
