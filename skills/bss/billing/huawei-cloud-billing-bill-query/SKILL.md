---
name: huawei-cloud-billing-bill-query
description: |
  Query the Huawei Cloud BSS (Business Support System) bills and fees of the
  current account within ONE billing cycle (one month). Supports three
  read-only queries: (1) bill fee records (账单费用记录/账单明细) for a
  billing cycle (YYYY-MM), (2) resource fee records / 流水账单 for a billing
  cycle, and (3) monthly cost breakdown (月度成本分析). Uses the
  huaweicloudsdkbss Python SDK (list_customer_bills_fee_records,
  list_customerself_resource_records, list_customer_bills_monthly_break_down;
  v2 API GET /v2/bills/customer-bills/fee-records,
  /v2/bills/customer-bills/res-fee-records,
  /v2/costs/cost-analysed-bills/monthly-breakdown) — KooCLI does NOT support
  the BSS service, so the SDK is the only execution path. The shipped
  scripts/query_bills.py integrates the execution-quality reporting SDK and
  reports every run to the skillsopr operations console. Time scope is limited
  to one month (the current month by default) — no multi-month or unbounded
  range queries. Read-only — never creates, modifies or deletes any billing
  resource.
  Use this skill whenever the user wants to check the current Huawei Cloud
  account's bills, fees, consumption records, 流水账单 or monthly cost within
  one month, e.g. for cost review, monthly expense check, or budget
  inspection.
  Triggers include: "查询账单", "账单查询", "费用查询", "查询费用", "消费记录",
  "流水账单", "月度账单", "月度费用", "账单明细", "查账单", "bill query",
  "query bill", "query fees", "billing records", "monthly bill", "cost
  breakdown", "消费明细", "费用明细".
tags:
  - huawei-cloud
  - bss
  - billing
  - bill
  - query
---

# Huawei Cloud Billing Bill Query Skill

## Overview

This skill queries the **Huawei Cloud BSS (Business Support System) bills and
fees of the current account within one billing cycle (one month)** via the BSS
v2 API and returns a report. It supports three read-only actions:

| Action | What it returns | BSS v2 API |
|--------|-----------------|------------|
| `fee-records` | Bill fee records (账单费用记录/账单明细) for a billing cycle: service, resource, region, consume/trade time, consume amount, cash/credit/coupon amounts | `list_customer_bills_fee_records` |
| `res-fee-records` | Resource fee records / 流水账单 for a billing cycle: per-resource usage, unit price, amount, cash/credit/coupon amounts | `list_customerself_resource_records` |
| `breakdown` | Monthly cost breakdown (月度成本分析) for a shared month: amortized amounts per resource | `list_customer_bills_monthly_break_down` |

The time scope is deliberately limited to **one month**: the default billing
cycle is the current month (`YYYY-MM`), and the user can pick any single month.
Multi-month or unbounded range queries are not supported.

It is a **read-only inspection skill**: it never creates, modifies, or deletes
any billing resource.

**Architecture:**

```text
Agent → scripts/query_bills.py (quality-reporting wrapper)
       → huaweicloudsdkbss Python SDK (BssClient)
       → Huawei Cloud BSS v2 API (global endpoint https://bss.myhuaweicloud.com)
```

**API paths (verified from `huaweicloudsdkbss` v2 SDK `_http_info`):**

| Operation | Method | API Path |
|-----------|--------|----------|
| Query bill fee records | GET | `/v2/bills/customer-bills/fee-records` |
| Query resource fee records (流水账单) | GET | `/v2/bills/customer-bills/res-fee-records` |
| Query monthly cost breakdown | GET | `/v2/costs/cost-analysed-bills/monthly-breakdown` |

**Execution-quality reporting:** every invocation of
`scripts/query_bills.py` reports a trace_id, status
(`success` / `biz_fail` / `sys_fail`), error code and cost to the skillsopr
operations console via the vendored `scripts/skill_quality_sdk.py`. Reporting
is non-blocking and fails silently; it never affects the query result.

**Applicable Scenarios:**

- Monthly expense check: "how much did I spend last month" / "查一下这个月的账单"
- Cost review: enumerate consumption per service / resource for one month
- 流水账单 inspection: per-resource usage and unit prices for one billing cycle
- Budget check: monthly cost breakdown with amortized amounts
- Daily inspection: quick bill snapshot of the current month

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询当前账号一个月内的账单/费用**（账单费用记录、流水账单、
> 月度成本分析）。不查询余额/余额变动，不创建、修改、删除任何账单或资源，
> 不支持跨多个月的查询。
> 若用户询问"查余额"、"导出账单"、"开票"、"充值/退款"等，请明确告知本 Skill
> 不提供该能力。

## Prerequisites

1. **Python 3.8+** with `huaweicloudsdkbss` and `huaweicloudsdkcore` packages —
   See `references/cli-installation-guide.md` (KooCLI does NOT support BSS, so
   the SDK is the only execution path)
2. **Huawei Cloud AK/SK** in environment variables
   (`HUAWEI_ACCESS_KEY`/`HUAWEI_SECRET_KEY` or
   `HUAWEICLOUD_SDK_AK`/`HUAWEICLOUD_SDK_SK`) — must belong to the account
   whose bills are queried
3. **IAM permissions** — `bss:bill:view` (or the system policy
   `BSS ReadOnlyAccess`) is required to query bills. See
   `references/iam-policies.md`
4. BSS is a **global service** — no region parameter is required; the client
   uses `GlobalCredentials` against `https://bss.myhuaweicloud.com`

## Workflow

1. **Identify the intent** — Confirm the user wants to query bills/fees
   (账单/费用/流水账单/月度成本) of the current account.
2. **Determine the billing cycle** — Default to the current month (`YYYY-MM`);
   let the user override with a single month. Only one month is supported.
3. **Choose the action** — `fee-records` (账单费用记录) is the default;
   use `res-fee-records` for 流水账单 or `breakdown` for monthly cost analysis.
4. **Run the query** — Execute `scripts/query_bills.py` with the requested
   action and cycle; optionally narrow the date range with
   `--bill-date-begin` / `--bill-date-end`.
5. **Present the results** — Show the per-record amounts and totals
   (consume/cash/coupon), or the raw JSON with `--format json`.
6. **Handle errors** — Missing AK/SK (`C01`), invalid cycle/date format
   (`U02`), missing cycle (`U01`), or no records (`U03`) are reported with
   the quality SDK error codes. Parameter validation is client-side and
   fail-fast: dates must fall within the selected billing cycle, `--limit`
   must be 1-100, `--offset` must be >= 1, and action-specific parameters
   (`--shared-month`, `--bill-date-*`, `--bill-type`) are rejected with a
   clear `U02` message when used with an incompatible action.

## Core Commands

> This skill uses the Python SDK (KooCLI does not support BSS). Run from the
> skill directory:
> `python3 scripts/query_bills.py [options]`

### Query bill fee records (default action, current month)

```bash
python3 scripts/query_bills.py
```

### Query bill fee records for a specific month (JSON)

```bash
python3 scripts/query_bills.py --action fee-records --bill-cycle 2026-07 --format json
```

### Query resource fee records (流水账单) for one month

```bash
python3 scripts/query_bills.py --action res-fee-records --cycle 2026-07
```

### Narrow to a date range within the month

```bash
python3 scripts/query_bills.py --action res-fee-records --cycle 2026-07 \
  --bill-date-begin 2026-07-01 --bill-date-end 2026-07-31
```

### Query monthly cost breakdown (月度成本分析)

```bash
python3 scripts/query_bills.py --action breakdown --shared-month 2026-07 --limit 20
```

### Filter by bill type (1=consumption, 2=refund, 3=adjustment, 4=timed, 5=arrears)

```bash
python3 scripts/query_bills.py --action fee-records --bill-cycle 2026-07 --bill-type 1
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--action` | No | Query action: `fee-records` (default), `res-fee-records`, `breakdown` | `fee-records` |
| `--bill-cycle` | No | Billing cycle `YYYY-MM` (fee-records); default current month | `2026-07` |
| `--cycle` | No | Billing cycle `YYYY-MM` (res-fee-records); default current month | `2026-07` |
| `--shared-month` | No | Shared month `YYYY-MM` (breakdown); default current month | `2026-07` |
| `--bill-date-begin` | No | Start date `YYYY-MM-DD` within the month (fee-records / res-fee-records) | `2026-07-01` |
| `--bill-date-end` | No | End date `YYYY-MM-DD` within the month (fee-records / res-fee-records) | `2026-07-31` |
| `--bill-type` | No | Bill type: 1=consumption, 2=refund, 3=adjustment, 4=timed, 5=arrears | `1` |
| `--offset` | No | Page offset (>=1) | `1` |
| `--limit` | No | Max records per page (1-100) | `10` |
| `--format` | No | Output format: `text` (default) or `json` | `json` |

## Reference Documents

- `references/cli-installation-guide.md` — Python SDK installation and AK/SK configuration (KooCLI does not support BSS)
- `references/iam-policies.md` — Least-privilege IAM policies (`bss:bill:view`)
- `references/verification-method.md` — Verification method and manual checks
- `references/dataflow-diagram.md` — Mermaid data flow diagram
- `references/acceptance-criteria.md` — Acceptance criteria

## KooCLI Command Format Standard

> KooCLI (`hcloud`) does **not** support the BSS service — `hcloud BSS --help`
> returns "Unsupported service: BSS". This skill therefore uses the Python
> SDK (`huaweicloudsdkbss`) as its only execution path; no hcloud commands are
> used.
