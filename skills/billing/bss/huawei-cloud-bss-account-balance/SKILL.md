---
name: huawei-cloud-bss-account-balance
description: |
  Query the Huawei Cloud account balance (cash/credit account available amount and debt) and the account change records (recharge/consume/refund/adjust) over a configurable time window, defaulting to the last 6 months. Uses the BSS (Business Support System) customer API via the huaweicloudsdkbss SDK, consistent with the console Billing Center.
  Use when the user wants to: (1) check the current Huawei Cloud account balance, (2) review income/expense records for the last ~half year, (3) verify recharge/consume history, (4) monitor account funds before deployments or renewals.
  Triggers include: "华为云余额", "账号余额", "账户余额", "查询余额", "余额查询", "近半年流水", "收支明细", "充值记录", "消费记录", "account balance", "Huawei Cloud balance", "balance query", "change records", "spending history", "billing", "BSS"
---

# Huawei Cloud BSS Account Balance Query

Query the Huawei Cloud account balance and the account change records
(recharge / consumption / refund / adjustment) over the last 6 months by
default, using the BSS customer API (`huaweicloudsdkbss` SDK). The data
returned is consistent with the Billing Center console.

## Overview

This skill wraps two read-only BSS customer APIs:

| Feature | SDK method | REST endpoint (verified from SDK source) |
|---------|-----------|------------------------------------------|
| Current account balance | `show_customer_account_balances` | `GET /v2/accounts/customer-accounts/balances` |
| Account change records (income/expense) | `list_customer_account_change_records` | `GET /v2/accounts/customer-accounts/account-change-records` |

Both endpoints were verified from the `huaweicloudsdkbss` v2 SDK source (`bss_client.py` `_http_info`). BSS is a **global** service: the client must use `GlobalCredentials` + `with_endpoints(["https://bss.myhuaweicloud.com"])`.

**Applicable scenarios:**

- "How much balance does my Huawei Cloud account have?" — quick funds check
- "Show my income/expense records for the last 6 months" — half-year financial review
- "Verify my recent recharges / consumption" — reconciliation before renewal or deployment

## Architecture

```
Huawei Cloud BSS Account Balance Query
└── QueryBssAccountBalance (read-only)
    └── scripts/bss_balance_query.py
        ├── huaweicloudsdkbss SDK (show_customer_account_balances,
        │        list_customer_account_change_records)
        └── scripts/skill_quality_sdk.py (quality reporting, non-blocking)
```

## Prerequisites

> **Prerequisite check: Python3 + huaweicloudsdkbss required**
>
> ```bash
> python3 --version  # Python3 >= 3.8
> python3 -c "import huaweicloudsdkbss; print('OK')"  # BSS SDK
> ```
>
> If the SDK is not installed: `pip3 install --user huaweicloudsdkbss`

---

## Authentication

> **Prerequisite check: Huawei Cloud credentials required**

> **Security rules (must be followed):**
>
> - **Prohibited** from reading, echoing, or printing AK/SK values
> - **Prohibited** from asking the user to input AK/SK directly in the conversation
> - **Prohibited** from accepting AK/SK directly provided by the user in the conversation
> - **Only allowed** to read credentials from environment variables or a credentials file

> **⚠️ Important: Handling user-provided credentials**
>
> If a user attempts to provide AK/SK directly (e.g. "my AK is xxx, SK is yyy"):
>
> 1. **Stop immediately** - Do not execute any commands
> 2. **Politely refuse** and return the following message:
>
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
>    ```
>
> 3. **Do not continue** executing any Huawei Cloud operations until credentials are configured

> **Check environment variables:**
>
> ```bash
> echo $HW_ACCESS_KEY  # Check if AK is set
> ```
>
> If not set, prompt the user to configure credentials using one of the methods above.

---

## IAM Permission Policies

Ensure the IAM user has the required permissions. See [references/iam-policies.md](references/iam-policies.md) for details.

**Minimum required permissions:**

- `bss:balance:view` — Query account balance
- `bss:bill:view` — Query account change records / bills

---

## Core Workflow

### Task 1: Query Current Account Balance (FP-01)

```bash
python3 scripts/bss_balance_query.py --balance-type BALANCE_TYPE_DEBIT
```

### Task 2: Query Last-6-Months Change Records (FP-02)

```bash
# Default: last 6 months, cash account
python3 scripts/bss_balance_query.py

# Explicit time window (e.g. last 6 months)
python3 scripts/bss_balance_query.py \
  --begin $(date -d '6 months ago' +%Y-%m-%d) --end $(date +%Y-%m-%d)

# Credit account / pagination
python3 scripts/bss_balance_query.py --balance-type BALANCE_TYPE_CREDIT --offset 0 --limit 100
```

Both queries run together in one invocation and print a combined JSON result:

- `balance.account_balances[]` — amount / currency / credit_amount per account type
- `balance.debt_amount` — outstanding debt
- `change_records.records[]` — trade_time / trade_id / trade_detail_type / change_amount / balance_after_change / type
- `change_records.total_count` — total matching records in the window

## Core Commands

```bash
# 1. Quick balance check (cash account, last 6 months)
python3 scripts/bss_balance_query.py --balance-type BALANCE_TYPE_DEBIT

# 2. Balance + change records with explicit 6-month range
python3 scripts/bss_balance_query.py \
  --begin 2026-02-10 --end 2026-08-10 --limit 100

# 3. Credit account query
python3 scripts/bss_balance_query.py --balance-type BALANCE_TYPE_CREDIT --months 6

# 4. Raw API response (debugging)
python3 scripts/bss_balance_query.py --raw
```

## Parameter Confirmation

| Parameter | Required | Description | Default |
|-----------|----------|-------------|---------|
| `--balance-type` | No | `BALANCE_TYPE_DEBIT` (cash account) or `BALANCE_TYPE_CREDIT` (credit account); other values are rejected | `BALANCE_TYPE_DEBIT` |
| `--months` | No | Query window in months (half a year = 6); must be a positive integer | `6` |
| `--begin` / `--end` | No | Explicit date range `YYYY-MM-DD`; **must be provided together**, otherwise the script exits with a clear error | auto (last N months) |
| `--offset` | No | Page offset for change records | `0` |
| `--limit` | No | Page size for change records, **1–100** (BSS caps at 100; larger values are rejected with a hint) | `100` |
| `--raw` | No | Print raw API response instead of the summary | off |

> **Input validation:** the script validates `--begin`/`--end` pairing, date
> format (`YYYY-MM-DD`), `--begin <= --end`, `--balance-type` enum, `--limit`
> range and `--months` positivity *before* calling the API. Invalid input
> prints a readable `Error:` message on stderr and exits with code 1 (argparse
> type errors exit with code 2). SDK errors (`ClientRequestException`) are
> rendered as `BSS API error: code=..., message=...` with a fix suggestion
> instead of a raw traceback.

## Verification

See [references/verification-method.md](references/verification-method.md).

**Quick verification:**

```bash
export HW_ACCESS_KEY=<your-ak>
export HW_SECRET_KEY=<your-sk>
# 或使用标准华为云环境变量: HUAWEI_ACCESS_KEY/HUAWEI_SECRET_KEY 或 HUAWEICLOUD_SDK_AK/HUAWEICLOUD_SDK_SK
python3 scripts/bss_balance_query.py --balance-type BALANCE_TYPE_DEBIT --months 6
```

> **Quality reporting:** every run of `scripts/bss_balance_query.py` reports a
> trace_id, status (`success` / `biz_fail` / `sys_fail`), error code and cost to the
> skillsopr operations console via the vendored `scripts/skill_quality_sdk.py`.
> Reporting is non-blocking and fails silently; it never affects the query result.

---

## References

| Document | Description |
|----------|-------------|
| [iam-policies.md](references/iam-policies.md) | Least-privilege IAM permission policies |
| [verification-method.md](references/verification-method.md) | Verification steps |
| [dataflow-diagram.md](references/dataflow-diagram.md) | Mermaid data flow diagram |
| [acceptance-criteria.md](references/acceptance-criteria.md) | Correct/error pattern comparison |
| [bss-account-balance-api.md](references/bss-account-balance-api.md) | Verified BSS API and parameter details |
| [bss_balance_query.py](scripts/bss_balance_query.py) | Balance + change records query script |
| [skill_quality_sdk.py](scripts/skill_quality_sdk.py) | Vendored quality reporting SDK (non-blocking) |
