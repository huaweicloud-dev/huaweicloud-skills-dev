---
name: huawei-cloud-obs-total-size
description: >-
  Queries the total storage size of Huawei Cloud OBS (Object Storage Service)
  buckets and returns ONLY the size value — a single number, in bytes by
  default. Supports querying the total size of one bucket or the combined total
  across all buckets under the account. Uses the KooCLI obsutil-backed
  `hcloud OBS ls ... -du -bf=raw` command (primary) or the huaweicloudsdkobs
  Python SDK (fallback). Read-only — never creates, modifies or deletes any
  resource. Use this skill whenever the user wants to know the total size of an
  OBS bucket or the overall OBS storage usage, e.g. for capacity review, cost
  estimation or storage planning. Triggers include: OBS total size, OBS bucket
  size, total storage usage, bucket capacity, OBS大小, OBS总大小, OBS容量,
  桶大小, 查询OBS大小, 存储占用, OBS存储量.
tags:
  - huawei-cloud
  - obs
  - size
  - capacity
  - query
  - storage
---

# Huawei Cloud OBS Total Size Skill

## Overview

This skill queries the total size of Huawei Cloud OBS buckets and returns **only the size value** (a single number). It is a read-only statistics skill: it never creates, modifies, or deletes buckets, directories, or objects.

**Architecture:**

```
Agent → hcloud CLI (KooCLI OBS / obsutil, primary) → Huawei Cloud OBS API
       ↘ huaweicloudsdkobs Python SDK (fallback)            ↗
```

**Two query scopes:**

| Scope | Description | Example |
|-------|-------------|---------|
| Single bucket | Total size of one bucket only | `--bucket my-bucket` → `5002295` |
| All buckets (default) | Combined total size across all buckets under the account | `--all` → `9533151096` |

**Applicable Scenarios:**

- Capacity review: "how much storage does this bucket / my OBS account use?"
- Cost estimation: estimate OBS storage billing based on total bytes
- Storage planning: compare usage before migration or quota changes
- Compliance auditing: track total storage growth

## Prerequisites

1. **hcloud CLI** (KooCLI) installed and authenticated — See `references/cli-installation-guide.md`
2. **obsutil** installed — required by the `hcloud OBS ls` command (bundled with KooCLI or standalone)
3. **OBS credentials configured for obsutil** — `hcloud OBS ls` reads AK/SK/endpoint from the obsutil config file
   (`.obsutilconfig` in the user home directory), which is **separate** from the KooCLI account credentials
4. **Python 3.8+** with `huaweicloudsdkobs` package (SDK fallback) — `pip install huaweicloudsdkobs`
5. **IAM permissions** — `obs:bucket:ListBucket`, `obs:object:List`, `obs:bucket:ListAllMyBuckets`
   — See `references/iam-policies.md`

> **跨区域桶（Multi-region）**：`--all` 会从 `hcloud OBS ls` 的输出解析每个桶所属区域，并按桶所属区域
> 动态绑定 endpoint（CLI 用 `-e=obs.<region>.myhuaweicloud.com`，SDK 用桶的 location 构造客户端），
> 因此账号下存在多区域桶时仍可正确汇总。单个桶查询失败（桶不存在 / 无权限）会跳过并给出告警，
> 不会中断整次求和。

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

1. **Confirm the scope** — ask the user which OBS bucket to measure, or whether they want the total across all buckets
2. **Verify prerequisites** — `hcloud version`, `hcloud OBS ls -s -limit=1` to confirm obsutil credentials
3. **Run the query** — use the script `scripts/query_obs_total_size.py` (primary) with the appropriate flags
4. **Return the size** — the script prints a single number; relay that number to the user

## Core Commands

### Total Size of a Single Bucket (Primary)

Returns the total size of one bucket, in bytes:

```bash
python3 scripts/query_obs_total_size.py --bucket <bucket_name>
```

### Total Size Across All Buckets

Returns the combined total size of all buckets under the account, in bytes.
Buckets in regions other than the configured endpoint are queried with their
own regional endpoint automatically; a single inaccessible bucket is skipped
with a warning instead of aborting the whole sum:

```bash
python3 scripts/query_obs_total_size.py --all
```

`--all` is the default when `--bucket` is not given:

```bash
python3 scripts/query_obs_total_size.py
```

### Different Output Units

```bash
# MB
python3 scripts/query_obs_total_size.py --all --unit mb

# Human readable (e.g. 8.88GB)
python3 scripts/query_obs_total_size.py --all --human
```

### Force SDK Executor

If the CLI/obsutil path is unavailable, force the Python SDK:

```bash
python3 scripts/query_obs_total_size.py --all --executor sdk
```

### Direct CLI Command (for reference)

The underlying obsutil command the script uses for a single bucket is
`hcloud OBS ls obs://<bucket_name>/ -du -bf=raw`, which prints
`[DU] Total bucket size: N`. Prefer the script commands above; use the raw
obsutil command only for manual inspection.

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--bucket` | No* | OBS bucket name to measure | `my-bucket` |
| `--all` | No* | Total size across all buckets (default) | `--all` |
| `--unit` | No | Output unit: `bytes`, `kb`, `mb`, `gb` | `--unit mb` |
| `--human` | No | Human readable size (e.g. `4.77MB`) | `--human` |
| `--region` | No | Huawei Cloud region (SDK fallback only) | `cn-north-4` |
| `--executor` | No | `auto` (default), `cli`, or `sdk` | `--executor sdk` |

\* Either `--bucket` or `--all` must be chosen; `--all` is the default when neither is given.

## Reference Documents

- [CLI Installation Guide](references/cli-installation-guide.md)
- [IAM Policies](references/iam-policies.md)
- [Verification Method](references/verification-method.md)
- [Data Flow Diagram](references/dataflow-diagram.md)
- [Acceptance Criteria](references/acceptance-criteria.md)

## KooCLI Command Format Standard

The `hcloud OBS` module is backed by obsutil. The `-du` flag queries the size of a storage space and `-bf=raw` prints bytes exactly:

| Feature | Description | Example |
|---------|-------------|---------|
| Service name | `OBS` (obsutil-backed) | `hcloud OBS ls` |
| Operation name | Lowercase obsutil command | `ls` |
| Query size | `-du` flag obtains the size of the specified storage space | `hcloud OBS ls obs://bucket/ -du` |
| Byte format | `-bf=raw` prints sizes in exact bytes | `hcloud OBS ls obs://bucket/ -du -bf=raw` |
| Credentials | obsutil config file (`.obsutilconfig`) | `-i=AK -k=SK -e=endpoint` |
