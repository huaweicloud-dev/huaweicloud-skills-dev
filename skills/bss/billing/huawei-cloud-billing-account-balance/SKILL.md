---
name: huawei-cloud-billing-account-balance
description: |
  Query the Huawei Cloud BSS (Business Support System) customer account balance
  of the current account and return a balance report. Returns the currency,
  total debt amount, and per-account balances (cash/balance account, credit
  account, reward account, deposit account) with amounts. Uses the
  huaweicloudsdkbss Python SDK (`show_customer_account_balances`, v2 API
  `GET /v2/accounts/customer-accounts/balances`) — KooCLI does NOT support the
  BSS service, so the SDK is the only execution path. The shipped
  scripts/query_account_balance.py integrates the execution-quality reporting
  SDK and reports every run to the skillsopr operations console.
  Read-only — never creates, modifies or deletes any billing resource.
  Use this skill whenever the user wants to check the personal Huawei Cloud
  account balance, remaining balance, debt, or billing account status, e.g. for
  cost review, before creating pay-per-use resources, or daily inspection.
  Triggers include: "账户余额", "余额查询", "查询余额", "账单余额", "我的余额",
  "欠费", "account balance", "query balance", "billing balance", "balance check",
  "remaining balance", "debt amount", "账户欠款".
tags:
  - huawei-cloud
  - bss
  - billing
  - balance
  - query
---

# Huawei Cloud Billing Account Balance Skill

## Overview

This skill queries the **customer account balance** of the current Huawei Cloud
account via the BSS (Business Support System) v2 API and returns a **balance
report**: the billing currency, the total debt amount, and each sub-account
balance (cash/balance account, credit account, reward account, deposit
account) with its amount. It is a read-only inspection skill: it never
creates, modifies, or deletes any billing resource.

**Architecture:**

```text
Agent → scripts/query_account_balance.py (quality-reporting wrapper)
       → huaweicloudsdkbss Python SDK (BssClient.show_customer_account_balances)
       → Huawei Cloud BSS v2 API
```

**API path (verified from `huaweicloudsdkbss` v2 SDK `_show_customer_account_balances_http_info`):**

| Operation | Method | API Path |
|-----------|--------|----------|
| Show customer account balances | GET | `/v2/accounts/customer-accounts/balances` |

> **CLI availability:** the KooCLI (`hcloud`) does **not** support the BSS
> service (`hcloud BSS` returns "Unsupported service: BSS"), so this skill uses
> the Python SDK as its only execution path. See
> `references/cli-installation-guide.md` for SDK setup.

**Execution-quality reporting:** every invocation of
`scripts/query_account_balance.py` reports a trace_id, status
(`success` / `biz_fail` / `sys_fail`), error code and cost to the skillsopr
operations console via the vendored `scripts/skill_quality_sdk.py`. Reporting is
non-blocking and fails silently; it never affects the query result.

**Applicable Scenarios:**

- Balance check: "how much balance do I have left in my Huawei Cloud account?"
- Pre-purchase check: confirm enough balance before creating pay-per-use resources
- Debt monitoring: check the total debt amount (`debt_amount`) for arrears
- Daily inspection: snapshot of all sub-account balances (cash, credit, reward, deposit)

> **能力边界（Capability Boundary）：**
> 本 Skill **仅查询华为云账户余额（BSS 账户余额）**。不查询/导出账单明细
> （费用账单、流水账单）、不查询资源用量、不执行充值/退款/转账/开票等任何
> 资金操作，也不查询代金券/优惠券。若用户询问"查询消费明细/账单列表"、
> "充值"、"开发票"等，请明确告知本 Skill 不提供该能力。

## Prerequisites

1. **Python 3.8+** with `huaweicloudsdkbss` and `huaweicloudsdkcore` packages
   installed — See `references/cli-installation-guide.md`
2. **Huawei Cloud AK/SK** — provided via environment variables
   (`HUAWEI_ACCESS_KEY` / `HUAWEI_SECRET_KEY`, or
   `HUAWEICLOUD_SDK_AK` / `HUAWEICLOUD_SDK_SK`). The AK/SK must belong to the
   account whose balance is queried. Never hardcode credentials into files.
3. **IAM permissions** — `bss:balance:view` (or the system policy
   `BSS ReadOnlyAccess`) is required to query account balances.
   See `references/iam-policies.md`
4. BSS is a **global service** — no region parameter is required; the SDK must
   use `GlobalCredentials` with the endpoint `https://bss.myhuaweicloud.com`.

## Workflow

1. **Identify the intent** — Confirm the user wants the current Huawei Cloud
   account balance / debt status.
2. **Check credentials** — Ensure AK/SK environment variables are set for the
   target account.
3. **Run the query** — Execute the wrapper script (SDK mode, see Core Commands).
4. **Present the report** — Show currency, debt amount, and each sub-account
   balance; highlight arrears if `debt_amount > 0`.
5. **Handle errors** — Missing AK/SK, insufficient IAM permissions, or network
   failures are reported with a quality error code and a clear message.

## Core Commands

### Query account balance (default, text report)

```bash
python3 scripts/query_account_balance.py
```

### Query account balance as JSON

```bash
python3 scripts/query_account_balance.py --format json
```

### Disable quality reporting (local debugging)

```bash
SKILL_QUALITY_DISABLE=1 python3 scripts/query_account_balance.py
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--format` | No | Output format: `text` (default) or `json` | `json` |
| `--executor` | No | Execution mode; `sdk` is the only supported mode for BSS | `sdk` |
| `HUAWEI_ACCESS_KEY` | Yes (env) | Huawei Cloud access key | via environment |
| `HUAWEI_SECRET_KEY` | Yes (env) | Huawei Cloud secret key | via environment |

> **Note:** No `--cli-region` is needed — BSS is a global service and KooCLI
> does not support it. The SDK connects to `https://bss.myhuaweicloud.com`.

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Least-privilege IAM permissions
- [CLI Installation Guide](references/cli-installation-guide.md) — Python SDK setup and authentication
- [Verification Method](references/verification-method.md) — How to verify the skill works
- [Dataflow Diagram](references/dataflow-diagram.md) — Request flow diagram
- [Acceptance Criteria](references/acceptance-criteria.md) — Acceptance test checklist
