---
name: huawei-cloud-obs-file-count
description: |-
  Counts the total number of files (objects) inside a Huawei Cloud OBS
  (Object Storage Service) bucket and returns ONLY the numeric count.
  Supports counting all files in a whole bucket or all files under a given
  prefix (folder). Zero-byte folder-marker keys (ending with '/') are
  excluded — only real files/objects are counted. Uses the KooCLI
  obsutil-backed `hcloud OBS ls ... -limit=0` command (primary, parses the
  "File number" line) or the huaweicloudsdkobs Python SDK (fallback,
  paginated ListObjects). Read-only — never creates, modifies or deletes any
  resource. Use this skill whenever the user wants to know how many files or
  objects an OBS bucket (or a folder inside it) contains, e.g. for inventory,
  capacity review, migration planning or compliance checks. Triggers include:
  "count OBS files", "OBS file count", "number of files in bucket",
  "how many objects in bucket", "OBS object count", "OBS文件数量",
  "查询OBS文件总数", "OBS文件总数", "桶里有多少个文件", "统计文件数量",
  "对象数量", "查询对象总数".
tags:
  - huawei-cloud
  - obs
  - file
  - count
  - query
  - inventory
---

# Huawei Cloud OBS File Count Skill

## Overview

This skill counts the number of files (objects) in a Huawei Cloud OBS bucket and returns **only the count**
(a single integer). It is a read-only statistics skill: it never creates, modifies, or deletes buckets,
directories, or objects.

**Architecture:**

```
Agent → hcloud CLI (KooCLI OBS / obsutil, primary) → Huawei Cloud OBS API
       ↘ huaweicloudsdkobs Python SDK (fallback)            ↗
```

**Two counting scopes:**

| Scope | Description | Example |
|-------|-------------|---------|
| Whole bucket (default) | Total number of files in the entire bucket | `--bucket my-bucket` → 1827 |
| Under a prefix | Total number of files under one folder/prefix | `--bucket my-bucket --prefix photos` → 42 |

**What counts as a file:** an object whose key does **not** end with a slash. Zero-byte folder-marker keys —
keys whose name ends in a slash (e.g. `photos`) — are directory markers, not files, and are excluded
automatically by both executors.

**Applicable Scenarios:**

- Inventory: "how many files does this bucket hold?"
- Migration planning: estimate object count before moving data
- Cost review: object-count-based billing estimates
- Compliance auditing: detect unexpected file volumes

> **能力边界（Capability Boundary）：**
> 本 Skill **仅统计文件/对象数量**，**不统计目录（文件夹）数量、不统计总存储大小、不统计流量**。
> 若用户询问"桶里有多少个目录/文件夹"，请引导使用目录统计类 OBS 技能；若询问总存储量或流量，
> 请引导使用容量/统计类 OBS 技能或华为云控制台 OBS 监控页。

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **obsutil** installed — required by the `hcloud OBS ls` command (bundled with KooCLI or standalone)
3. **OBS credentials configured for obsutil** — `hcloud OBS ls` reads AK/SK/endpoint from the obsutil config file
   (`.obsutilconfig` in the user home directory), which is **separate** from the KooCLI account credentials
4. **Python 3.8+** with `huaweicloudsdkobs` package (SDK fallback) — `pip install huaweicloudsdkobs`
5. **IAM permissions** — `obs:bucket:ListBucket`, `obs:object:List` — See `references/iam-policies.md`

> **OBS credentials are separate.** Before running, check whether obsutil credentials are configured:
>
> ```bash
> hcloud OBS ls -s -limit=1
> ```
>
> If the output is `Please set ak, sk and endpoint in the configuration file!` or an `InvalidAccessKeyId` error,
> obsutil credentials are not configured. Ask the user to configure them in their own terminal (never ask the user
> to paste AK/SK into the conversation). Provide the following example command:
>
> ```
> hcloud obs config -i=<YourAK> -k=<YourSK> -e=obs.<Region>.myhuaweicloud.com
> ```
>
> Example (cn-north-4): `hcloud obs config -i=<YourAK> -k=<YourSK> -e=obs.cn-north-4.myhuaweicloud.com`

## Workflow

1. **Confirm the scope** — ask the user which OBS bucket to inspect, and optionally a subdirectory prefix
2. **Verify prerequisites** — `hcloud version`, `hcloud OBS ls -s -limit=1` to confirm obsutil credentials
3. **Run the count** — use the script `scripts/count_obs_files.py` (primary) with the appropriate flags
4. **Return the count** — the script prints a single integer; relay that integer to the user
5. **Handle errors** — if the script fails (e.g. bucket not found, invalid AK/SK, missing credentials), the script
   prints a clear Chinese error hint on stderr with configuration guidance; relay that hint to the user

## Core Commands

### Count All Files in a Bucket (Primary)

Returns the total number of files in the whole bucket:

```bash
python3 scripts/count_obs_files.py --bucket <bucket_name>
```

### Count Files Under a Prefix

Returns the total number of files under a folder/prefix (the prefix itself is
normalized: a trailing slash is optional):

```bash
python3 scripts/count_obs_files.py --bucket <bucket_name> --prefix <prefix>
```

Example:

```bash
python3 scripts/count_obs_files.py --bucket my-bucket --prefix photos
```

### Force a Specific Executor

```bash
# Force the CLI (hcloud OBS ls) path
python3 scripts/count_obs_files.py --bucket <bucket_name> --executor cli

# Force the SDK (huaweicloudsdkobs) path
python3 scripts/count_obs_files.py --bucket <bucket_name> --executor sdk

# Explicit region (default: cn-north-4)
python3 scripts/count_obs_files.py --bucket <bucket_name> --region cn-east-3
```

The default `--executor auto` tries the CLI first and falls back to the SDK only for
infrastructure errors (missing hcloud binary, timeout). Definitive service errors
(NoSuchBucket, AccessDenied, InvalidAccessKeyId) are reported directly with a clear
Chinese hint instead of triggering a fallback.

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--bucket` | Yes | OBS bucket name | `my-bucket` |
| `--prefix` | No | Count files under this prefix/folder only (trailing slash optional) | `photos` |
| `--region` | No | Huawei Cloud region (default `cn-north-4`) | `cn-east-3` |
| `--executor` | No | `auto` (default) \| `cli` \| `sdk` | `sdk` |

## KooCLI Command Format Standard

```bash
hcloud <Service> <Operation> --cli-region=<region> [--key=value ...]
```

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | Exact KooCLI Service name beginning with uppercase/title case | `OBS` |
| Operation name | PascalCase | `ls` (obsutil command) |
| Region parameter | Endpoint configured via obsutil config, not `--cli-region` | `-e=obs.cn-north-4.myhuaweicloud.com` |
| Simple parameter | `--key=value` | `-limit=0` |

> Note: the `hcloud OBS ls` command is an obsutil-backed wrapper. Bucket/endpoint
> targeting is configured in the obsutil config file (`.obsutilconfig` in the user home directory), so `--cli-region` is not used for
> this command; the equivalent region control is the obsutil `endpoint` setting.

## Verification Method

See `references/verification-method.md` for full verification steps, and
`references/acceptance-criteria.md` for the acceptance checklist. The bundled
test script runs a functional smoke test:

```bash
bash scripts/test-cli-commands.sh <skill-path>
```

## Reference Documents

- `references/cli-installation-guide.md` — hcloud (KooCLI) and obsutil installation, obsutil credential configuration, troubleshooting
- `references/iam-policies.md` — least-privilege IAM policy (read-only)
- `references/verification-method.md` — CLI/SDK cross-check verification steps
- `references/dataflow-diagram.md` — Mermaid architecture and sequence diagrams
- `references/acceptance-criteria.md` — functional, security and quality acceptance criteria
