---
name: huawei-cloud-maas-tokens-usage
description: |
  Query Huawei Cloud MaaS (Model as a Service) tokens usage statistics, including total tokens, prompt tokens, completion tokens, total requests, and total errors. Supports preset service, my service, and custom endpoint with time range queries (last 7/14/30 days or custom). Data source is MaaS ShowStatistics API, consistent with console.
  Use when the user wants to: (1) query MaaS token consumption statistics, (2) check MaaS service request counts and error rates, (3) analyze token usage for preset service or my service, (4) monitor MaaS usage over a specific time period.
  Triggers include: "MaaS", "Model as a Service", "tokens usage", "token consumption", "request count", "error count", "MaaS usage", "preset service usage", "completion tokens", "prompt tokens", "MaaS statistics", "模型服务", "令牌用量", "token统计", "token用量", "词元用量", "请求次数", "MaaS监控", "华为云MaaS"
---

# Huawei Cloud MaaS Tokens Usage Monitoring

Query Huawei Cloud MaaS (Model as a Service) usage statistics, including total tokens, prompt tokens, completion tokens, total requests, and total errors. Supports querying last 7 days, 14 days, 30 days, or custom time ranges. Default query type is MaaS preset service.

## Overview

This skill wraps the MaaS ShowStatistics API (`POST /v1/{project_id}/maas/monitoring/show-statistics`, only available in `cn-southwest-2`) with a Python script that performs AK/SK-signed requests. It aggregates token consumption (total / prompt / completion), request count, error count, and error rate over a configurable time range, auto-segmenting ranges longer than 29 days. Data returned is consistent with the MaaS console monitoring page.

**Applicable scenarios:**
- Daily/weekly MaaS usage review: "how many tokens did my MaaS services consume last week?"
- Cost & quota analysis: compare preset service vs. my service vs. custom endpoint usage
- Error-rate monitoring: track request errors over 7/14/30 days or a custom period

## Architecture

```
Huawei Cloud MaaS Tokens Usage Monitoring
└── GetMaaSTokensUsage  (via MaaS ShowStatistics API)
    └── scripts/maas_rest_usage_stats.py
        └── scripts/skill_quality_sdk.py (quality reporting, non-blocking)
```

## Prerequisites

> **Prerequisite check: Python3 + huaweicloudsdkcore required**
> ```bash
> python3 --version  # Python3 >= 3.8
> python3 -c "import huaweicloudsdkcore; print('OK')"  # SDK signing library
> ```
> If SDK not installed: `pip3 install --user huaweicloudsdkcore`

---

## Authentication

> **Prerequisite check: Huawei Cloud credentials required**

> **Security rules (must be followed):**
> - **Prohibited** from reading, echoing, or printing AK/SK values
> - **Prohibited** from asking the user to input AK/SK directly in the conversation
> - **Prohibited** from accepting AK/SK directly provided by the user in the conversation
> - **Only allowed** to read credentials from environment variables or credentials file

> **⚠️ Important: Handling user-provided credentials**
>
> If a user attempts to provide AK/SK directly (e.g., "my AK is xxx, SK is yyy"):
> 1. **Stop immediately** - Do not execute any commands
> 2. **Politely refuse** and return the following message:
>    ```
>    For account security, please do not provide Huawei Cloud Access Key ID and Access Key Secret directly in the conversation.
>
>    Please use one of the following secure methods to configure credentials:
>
>    Method 1: Environment variables
>        export HW_ACCESS_KEY=<your-access-key-id>
>        export HW_SECRET_KEY=<your-access-key-secret>
>        (also supported: HUAWEI_ACCESS_KEY/HUAWEI_SECRET_KEY, HUAWEICLOUD_SDK_AK/HUAWEICLOUD_SDK_SK)
>
>    Method 2: Credentials file
>        Create a file (e.g., ~/aksk.txt) with AK on line 1, SK on line 2.
>        Then use: --credentials-file ~/aksk.txt
>
>    After configuration is complete, please retry your request.
>    ```
> 3. **Do not continue** executing any Huawei Cloud operations until credentials are configured

> **Check environment variables**:
> ```bash
> echo $HW_ACCESS_KEY  # Check if AK is set
> ```
> If not set, prompt the user to configure credentials using one of the methods above.

---

## IAM Permission Policies

Ensure the IAM user has the required permissions. See [references/iam-policies.md](references/iam-policies.md) for details.

**Minimum required permissions:**
- `modelarts:monitoring:get` — Query MaaS monitoring statistics
- `modelarts:service:get` — Query service information
- `iam:projects:get` — Auto-get project_id

---

## Core Workflow

### Task 1: Query MaaS Tokens Usage Statistics

Query MaaS usage statistics via the ShowStatistics API. Data is consistent with the console.

📄 Detailed steps → [references/task-query-tokens-usage.md](references/task-query-tokens-usage.md)

---

## Core Commands

```bash
# Query last 7 days, preset service (default)
python3 scripts/maas_rest_usage_stats.py --from 2026-07-31 --to 2026-08-07

# My service (1) / preset service (2, default) / custom endpoint (4)
python3 scripts/maas_rest_usage_stats.py --from 2026-07-31 --to 2026-08-07 --service-type 1
python3 scripts/maas_rest_usage_stats.py --from 2026-07-31 --to 2026-08-07 --service-type 4

# Batch inference statistics
python3 scripts/maas_rest_usage_stats.py --from 2026-07-31 --to 2026-08-07 --infer-type batch

# Filter by API keys and show raw API response
python3 scripts/maas_rest_usage_stats.py --from 2026-07-31 --to 2026-08-07 --api-keys <key1> <key2> --raw
```

> Region defaults to `cn-southwest-2` (the only region where the MaaS ShowStatistics API is available); override with `--region <region>` if needed.

## Parameter Confirmation

| Parameter | Required | Description | Default |
|-----------|----------|-------------|---------|
| `--from` / `--to` | Yes | Query start/end date `YYYY-MM-DD` (range > 29 days is auto-segmented) | — |
| `--region` | No | Huawei Cloud region (MaaS monitoring only in `cn-southwest-2`) | `cn-southwest-2` |
| `--service-type` | No | 1 = My Service, 2 = Preset Service, 4 = Custom Endpoint | `2` |
| `--infer-type` | No | `real_time` or `batch` | `real_time` |
| `--api-keys` | No | Filter by API key list | — |
| `--raw` | No | Print raw API response | off |
| `--credentials-file` | No | Credentials file (KEY=VALUE / CSV / one-per-line) | env vars |

---

## Verification

See [references/verification-method.md](references/verification-method.md).

**Quick verification:**
```bash
export HW_ACCESS_KEY=<your-ak>
export HW_SECRET_KEY=<your-sk>
# 或使用标准华为云环境变量: HUAWEI_ACCESS_KEY/HUAWEI_SECRET_KEY 或 HUAWEICLOUD_SDK_AK/HUAWEICLOUD_SDK_SK
python3 scripts/maas_rest_usage_stats.py --from 2026-05-08 --to 2026-05-21
```

> **Quality reporting:** each run of `scripts/maas_rest_usage_stats.py` reports a
> trace_id, status (`success` / `biz_fail` / `sys_fail`), error code and cost to the
> skillsopr operations console via the vendored `scripts/skill_quality_sdk.py`.
> Reporting is non-blocking and fails silently; it never affects the query result.

---

## References

| Document | Description |
|----------|-------------|
| [task-query-tokens-usage.md](references/task-query-tokens-usage.md) | Task 1: Query tokens usage statistics |
| [related-apis.md](references/related-apis.md) | API and parameter details |
| [iam-policies.md](references/iam-policies.md) | IAM permission policies |
| [maas-metrics.md](references/maas-metrics.md) | MaaS monitoring metrics reference |
| [verification-method.md](references/verification-method.md) | Verification steps |
| [acceptance-criteria.md](references/acceptance-criteria.md) | Correct/error pattern comparison |
| [cli-installation-guide.md](references/cli-installation-guide.md) | Prerequisites installation guide |
| [troubleshooting.md](references/troubleshooting.md) | Troubleshooting and practical experience |
| [maas_rest_usage_stats.py](scripts/maas_rest_usage_stats.py) | ShowStatistics API usage statistics script |
| [skill_quality_sdk.py](scripts/skill_quality_sdk.py) | Vendored quality reporting SDK (non-blocking) |
