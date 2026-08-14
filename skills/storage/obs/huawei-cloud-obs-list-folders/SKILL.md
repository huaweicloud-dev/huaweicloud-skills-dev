---
name: huawei-cloud-obs-list-folders
description: |
  Lists the Huawei Cloud OBS (Object Storage Service) buckets of the current
  tenant and returns the FOLDER names inside a bucket — both the top-level
  folders of a bucket and the sub-folders under a given prefix. Uses the
  KooCLI obsutil-backed command `hcloud OBS ls` (primary, parses the
  "Folder list" section of obsutil output) or the huaweicloudsdkobs Python
  SDK (fallback, ListObjects with delimiter=/). Read-only — never creates,
  modifies or deletes any bucket, folder or object. Use this skill whenever
  the user wants to see which OBS buckets exist or which folders a bucket
  (or a folder inside it) contains, e.g. for daily inspection, inventory,
  data organization review or troubleshooting. Triggers include: "list OBS
  buckets", "OBS bucket list", "list folders in bucket", "OBS folder names",
  "查询OBS列表", "OBS桶列表", "OBS文件夹名称", "桶里有哪些文件夹",
  "查询obs列表", "返回obs列表中文件夹名称", "OBS目录列表".
tags:
  - huawei-cloud
  - obs
  - storage
  - list
  - query
---

# Huawei Cloud OBS List Folders Skill

## Overview

This skill queries the Huawei Cloud **OBS (Object Storage Service)** of the
current tenant and returns:

1. The **bucket list** — all OBS buckets owned by the tenant.
2. The **folder names** at the root of a bucket — top-level folders
   (prefixes ending in `/`).
3. The **sub-folder names** under a given folder/prefix inside a bucket.

It is a read-only inspection skill: it never creates, modifies or deletes
buckets, folders or objects.

**Architecture:**

```text
Agent → hcloud CLI (KooCLI OBS / obsutil, primary) → Huawei Cloud OBS API
       ↘ huaweicloudsdkobs Python SDK (fallback)            ↗
```

**API paths (verified from `huaweicloudsdkobs` v1 SDK `ObsClient` `_http_info`):**

| Operation | Method | API Path |
|-----------|--------|----------|
| List buckets | GET | `/` (ListBuckets) |
| List objects / folders in a bucket | GET | `/{bucket}` (ListObjects, `delimiter=/`) |

**Execution-quality reporting:** every invocation of
`scripts/list_obs_folders.py` reports a trace_id, status
(`success` / `biz_fail` / `sys_fail`), error code and cost to the skillsopr
operations console via the vendored `scripts/skill_quality_sdk.py`. Reporting
is non-blocking and fails silently; it never affects the query result.

**Applicable Scenarios:**

- Daily inspection: "which OBS buckets exist?" / "what folders are in this bucket?"
- Inventory: enumerate buckets and folder structure for data organization review
- Troubleshooting: locate the folder where a file is expected to be stored
- Cost/usage review: understand bucket layout before estimating storage usage
- Data governance: verify folder naming conventions across buckets

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询 OBS 桶列表与桶内文件夹名称**。不创建/删除/修改桶、
> 文件夹或对象，不统计文件数量，也不下载/上传对象内容。
> 若用户询问"创建/删除桶"、"统计文件数量"、"上传/下载文件"等，
> 请明确告知本 Skill 不提供该能力。

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See
   `references/cli-installation-guide.md`. The OBS service of KooCLI is
   obsutil-backed: `hcloud OBS <command>` maps to obsutil commands.
2. **Python 3.8+** with `huaweicloudsdkobs` package installed (SDK fallback only)
3. **IAM permissions** — `obs:bucket:ListAllMyBuckets` (list buckets) and
   `obs:bucket:ListBucket` / `obs:object:List` (list objects/folders in a
   bucket). The system policy `OBS ReadOnlyAccess` covers both. See
   `references/iam-policies.md`
4. A region where the tenant owns OBS buckets; specify it with `--cli-region`
   (buckets are global, but the region determines the obsutil endpoint)

## Workflow

1. **Identify the intent** — Confirm the user wants to list OBS buckets
   and/or folder names inside a bucket, and which bucket/prefix.
2. **Confirm parameters** — `{region}` (default `cn-north-4`) and optionally
   `{bucket}` / `{prefix}`.
3. **Run the query** — Use the CLI commands below (or the wrapper script).
4. **Present the results** — Show the bucket names, and for a bucket query
   show the folder names one per line.
5. **Handle errors** — If the CLI fails (credentials/permissions/network),
   retry with the SDK fallback described in `references/verification-method.md`.

## Core Commands

> KooCLI format: `hcloud <Service> <Operation> --cli-region=<region> [--params]`
>
> Note: KooCLI's OBS service delegates to obsutil, so the OBS commands use
> obsutil syntax (`hcloud OBS ls ...`) rather than a PascalCase operation.

### List all OBS buckets

```bash
hcloud OBS ls
```

Output: one line per bucket in the form `obs://<bucket-name>`.

### List folders at the root of a bucket

```bash
hcloud OBS ls obs://{bucket}
```

Output contains a `Folder list:` section — the folder names are the lines
under it (e.g. `obs://my-bucket/CloudTraces/`). Use the wrapper script to get
just the folder names:

```bash
python3 scripts/list_obs_folders.py --bucket {bucket} --folders-only
```

### List sub-folders under a prefix

> Note: the `-d` flag makes obsutil list the sub-folders *inside* the given
> folder. Without it, obsutil only echoes the folder matching the prefix
> itself.

```bash
hcloud OBS ls obs://{bucket}/{prefix} -d
python3 scripts/list_obs_folders.py --bucket {bucket} --prefix {prefix} --folders-only
```

### Compact: bucket names only

```bash
hcloud OBS ls | grep '^obs://'
```

### Wrapper script (recommended — includes quality reporting)

```bash
python3 scripts/list_obs_folders.py --region {region} --buckets-only   # bucket names only
python3 scripts/list_obs_folders.py --bucket {bucket} --folders-only   # folder names only
python3 scripts/list_obs_folders.py --bucket {bucket} --prefix photos  # sub-folders under prefix
```

The wrapper tries the CLI first, falls back to the `huaweicloudsdkobs` SDK,
and reports execution quality to the skillsopr console. Set
`SKILL_QUALITY_DISABLE=1` to disable reporting (local debugging).

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | No | Huawei Cloud region (default `cn-north-4`) | `cn-north-4` |
| `{bucket}` | Conditional | OBS bucket name (needed to list folders) | `my-bucket` |
| `{prefix}` | No | Folder/prefix inside the bucket | `photos` |
| `--folders-only` | No | Print only folder names (one per line) | — |
| `--buckets-only` | No | Print only bucket names (one per line) | — |
| `--executor` | No | `cli` / `sdk` / `auto` (default `auto`) | `sdk` |

## KooCLI Command Format Standard

The KooCLI command format is:

`hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]`

> Note: this is a generic format template, not an executable command — replace
> `<Service>`, `<Operation>`, `<region>` and the parameters with real values.
> For OBS, KooCLI delegates to obsutil: `hcloud OBS ls [obs://bucket[/prefix]] [-s] [-d] [-limit=N]`.

- Service name: `OBS` (starts with uppercase; the KooCLI OBS service is
  obsutil-backed).
- Region: always pass `--cli-region=<region>` for non-OBS services; for OBS
  the region is configured via the obsutil endpoint
  (`hcloud OBS config -e=obs.<region>.myhuaweicloud.com`).
- Simple parameters use `--key=value`; obsutil options use `-option` style
  (e.g. `-limit=1000`, `-s` for brief mode, `-d` to list sub-folders).

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Least-privilege IAM permissions
- [CLI Installation Guide](references/cli-installation-guide.md) — hcloud CLI setup and OBS/obsutil configuration
- [Verification Method](references/verification-method.md) — How to verify the skill works
- [Dataflow Diagram](references/dataflow-diagram.md) — Request flow diagram
- [Acceptance Criteria](references/acceptance-criteria.md) — Acceptance test checklist
