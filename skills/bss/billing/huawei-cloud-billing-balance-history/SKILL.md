---
name: huawei-cloud-billing-balance-history
description: |
  Query the Huawei Cloud BSS (Business Support System) account balance and its
  history across different time periods, and return a report. Supports three
  read-only queries: (1) current customer account balance (currency, total debt
  amount, per-account balances for cash/credit/reward/deposit), (2) balance
  change records (income/expense detail: recharge, consumption, refund, freeze,
  etc.) within a user-specified date range, and (3) monthly consumption summary
  for a user-specified billing cycle (YYYY-MM). Uses the huaweicloudsdkbss
  Python SDK (show_customer_account_balances, list_customer_account_change_records,
  show_customer_monthly_sum; v2 API GET /v2/accounts/customer-accounts/balances,
  /v2/accounts/customer-accounts/account-change-records,
  /v2/bills/customer-bills/monthly-sum) — KooCLI does NOT support the BSS
  service, so the SDK is the only execution path. The shipped
  scripts/query_balance_history.py integrates the execution-quality reporting
  SDK and reports every run to the skillsopr operations console.
  Read-only — never creates, modifies or deletes any billing resource.
  Use this skill whenever the user wants to check the personal Huawei Cloud
  account balance, balance over a time period, balance change records, income/
  expense detail, or monthly bill summary, e.g. for cost review, daily
  inspection, or debt monitoring.
  Triggers include: "账户余额", "余额查询", "查询余额", "账单余额", "我的余额",
  "不同时间段余额", "余额变动", "收支明细", "月度账单", "月度消费", "欠费",
  "account balance", "query balance", "balance history", "balance change",
  "income expense", "monthly bill", "monthly consumption", "debt amount".
tags:
  - huawei-cloud
  - bss
  - billing
  - balance
  - query
---

# Huawei Cloud Billing Balance History Skill

## Overview

This skill queries the **Huawei Cloud BSS (Business Support System) account
balance and its history across time periods** via the BSS v2 API and returns a
report. It supports three read-only actions:

| Action | What it returns | BSS v2 API |
|--------|-----------------|------------|
| `balance` | Current customer account balance: currency, total debt amount, per-account balances (cash/balance, credit, reward, deposit) | `show_customer_account_balances` |
| `changes` | Balance change records (income/expense detail) in a date range: recharge, consumption, refund, freeze, transfer, adjustment, etc. | `list_customer_account_change_records` |
| `monthly-sum` | Monthly consumption summary for a billing cycle (`YYYY-MM`): consume amount, debt, coupon/cash/credit amounts, per-service breakdown | `show_customer_monthly_sum` |

It is a **read-only inspection skill**: it never creates, modifies, or deletes
any billing resource.

**Architecture:**

```text
Agent → scripts/query_balance_history.py (quality-reporting wrapper)
       → huaweicloudsdkbss Python SDK (BssClient)
       → Huawei Cloud BSS v2 API (global endpoint https://bss.myhuaweicloud.com)
```

**API paths (verified from `huaweicloudsdkbss` v2 SDK `_http_info`):**

| Operation | Method | API Path |
|-----------|--------|----------|
| Show customer account balances | GET | `/v2/accounts/customer-accounts/balances` |
| List customer account change records | GET | `/v2/accounts/customer-accounts/account-change-records` |
| Show customer monthly sum | GET | `/v2/bills/customer-bills/monthly-sum` |

> **CLI availability:** the KooCLI (`hcloud`) does **not** support the BSS
> service (`hcloud BSS` returns "Unsupported service: BSS"), so this skill uses
> the Python SDK as its only execution path. See
> `references/cli-installation-guide.md` for SDK setup.

**Execution-quality reporting:** every invocation of
`scripts/query_balance_history.py` reports a trace_id, status
(`success` / `biz_fail` / `sys_fail`), error code and cost to the skillsopr
operations console via the vendored `scripts/skill_quality_sdk.py`. Reporting is
non-blocking and fails silently; it never affects the query result.

**Applicable Scenarios:**

- Daily inspection: "how much balance do I have left, and what changed last month?"
- Balance check: current cash/credit/reward/deposit balances and arrears
- Time-period review: balance change records (income/expense) between two dates
- Cost review: monthly consumption summary for a given billing cycle
- Debt monitoring: check `debt_amount` for arrears

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询华为云 BSS 账户余额及余额变动/月度消费汇总**。不导出账单
> 明细流水（资源消费记录逐条明细）、不查询资源用量、不执行充值/退款/转账/开票
> 等任何资金操作，也不查询代金券/优惠券。若用户询问"逐条消费明细导出"、
> "充值"、"开发票"等，请明确告知本 Skill 不提供该能力。

## Prerequisites

1. **Python 3.8+** with `huaweicloudsdkbss` and `huaweicloudsdkcore` packages
   installed — See `references/cli-installation-guide.md`
2. **Huawei Cloud AK/SK** — provided via environment variables
   (`HUAWEI_ACCESS_KEY` / `HUAWEI_SECRET_KEY`, or
   `HUAWEICLOUD_SDK_AK` / `HUAWEICLOUD_SDK_SK`). The AK/SK must belong to the
   account whose balance is queried. Never hardcode credentials into files.
3. **IAM permissions** — `bss:balance:view` (or the system policy
   `BSS ReadOnlyAccess`) is required to query account balances and bills.
   See `references/iam-policies.md`
4. BSS is a **global service** — no region parameter is required; the SDK must
   use `GlobalCredentials` with the endpoint `https://bss.myhuaweicloud.com`.

## Workflow

1. **Identify the intent** — Determine which query the user needs:
   - current balance → `balance`
   - balance over a time range / income-expense detail → `changes` (ask for
     start/end dates, e.g. `2026-07-01`..`2026-07-31`)
   - monthly bill summary → `monthly-sum` (ask for billing cycle, e.g. `2026-07`)
2. **Check credentials** — Ensure AK/SK environment variables are set for the
   target account.
3. **Run the query** — Execute the wrapper script (SDK mode, see Core Commands)
   with the confirmed parameters.
4. **Present the report** — Show the balance/change/monthly summary; highlight
   arrears if `debt_amount > 0`.
5. **Handle errors** — Missing AK/SK, invalid parameter formats, insufficient
   IAM permissions, or network failures are reported with a quality error code
   and a clear message.

## Core Commands

All commands are read-only SDK queries; no confirmation is required for execution.

### 1. Query current account balance (default)

```bash
python3 scripts/query_balance_history.py --action balance
```

### 2. Query balance change records in a date range

```bash
python3 scripts/query_balance_history.py --action changes \
  --balance-type DEBIT --begin 2026-07-01 --end 2026-07-31 --limit 20
```

- `--balance-type`: `DEBIT` (cash account) or `CREDIT` (credit account)
  (default `DEBIT`)
- `--begin` / `--end`: date range `YYYY-MM-DD` (optional; omitted = no bound)
- `--revenue-expense-type`: optional filter `REVENUE` (income) or `EXPENSE`
  (expense)
- `--limit`: page size 1–100 (default 10)

### 3. Query monthly consumption summary for a billing cycle

```bash
python3 scripts/query_balance_history.py --action monthly-sum \
  --bill-cycle 2026-07 --limit 20
```

- `--bill-cycle`: required, billing cycle in `YYYY-MM` format (e.g. `2026-07`)

### 4. JSON output (for automation / further processing)

```bash
python3 scripts/query_balance_history.py --action balance --format json
python3 scripts/query_balance_history.py --action changes --begin 2026-07-01 --end 2026-07-31 --format json
python3 scripts/query_balance_history.py --action monthly-sum --bill-cycle 2026-07 --format json
```

### 5. Disable quality reporting (local debugging)

```bash
SKILL_QUALITY_DISABLE=1 python3 scripts/query_balance_history.py --action balance
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--action` | Yes | Query action: `balance`, `changes`, `monthly-sum` | `changes` |
| `--balance-type` | No (default `DEBIT`) | Account type for `changes`: `DEBIT` / `CREDIT` | `DEBIT` |
| `--begin` | No | Start date `YYYY-MM-DD` for `changes` | `2026-07-01` |
| `--end` | No | End date `YYYY-MM-DD` for `changes` | `2026-07-31` |
| `--revenue-expense-type` | No | Filter for `changes`: `REVENUE` / `EXPENSE` | `EXPENSE` |
| `--bill-cycle` | Yes (for `monthly-sum`) | Billing cycle `YYYY-MM` | `2026-07` |
| `--limit` | No (default 10) | Page size 1–100 (BSS API max 100) | `20` |
| `--format` | No (default `text`) | Output format: `text` / `json` | `json` |

> When the user asks for a time period but gives no exact dates, ask for the
> start/end dates (or billing cycle) before running `changes` / `monthly-sum`.
> For `balance`, no parameters are required.

## KooCLI Command Format Standard

This skill does **not** use the KooCLI (`hcloud`): the BSS service is not
supported by KooCLI (`hcloud BSS` returns "Unsupported service: BSS"), so the
Python SDK (`huaweicloudsdkbss`) is the only execution path. The script
follows the standard `python3 scripts/query_balance_history.py --action <Action> [--param=value ...]`
convention with `--`-prefixed long options.

## Reference Documents

- `references/iam-policies.md` — Least-privilege IAM policies for balance/bill queries
- `references/cli-installation-guide.md` — SDK installation and AK/SK configuration
- `references/verification-method.md` — How to verify query results
- `references/dataflow-diagram.md` — Mermaid data flow diagram
- `references/acceptance-criteria.md` — Acceptance criteria

## Related Commands

| Command | Purpose |
|---------|---------|
| `bash scripts/validate-skill.sh {path}` | Structure and Huawei Cloud specification validation |
| `bash scripts/test-cli-commands.sh {path} --executor sdk` | Functional testing (SDK mode) |
