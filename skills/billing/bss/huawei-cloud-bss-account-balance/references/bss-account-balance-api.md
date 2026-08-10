# BSS Account Balance API Reference

Verified endpoints (from `huaweicloudsdkbss` v2 SDK source, `bss_client.py` `_http_info`).
BSS is a global service — endpoint `https://bss.myhuaweicloud.com`, client uses
`GlobalCredentials` + `with_endpoints`.

## 1. Show Customer Account Balances (FP-01)

- **SDK method:** `show_customer_account_balances`
- **REST:** `GET /v2/accounts/customer-accounts/balances`
- **Auth:** GlobalCredentials (AK/SK)

| Request field | Required | Description |
|---------------|----------|-------------|
| — | — | No required request fields |

| Response field | Description |
|----------------|-------------|
| `account_balances[]` | List of account balance entries |
| `account_balances[].account_type` | `BALANCE_TYPE_DEBIT` (cash) / `BALANCE_TYPE_CREDIT` (credit) |
| `account_balances[].amount` | Available amount |
| `account_balances[].currency` | Currency (e.g. `CNY`) |
| `account_balances[].credit_amount` | Credit amount |
| `debt_amount` | Outstanding debt |
| `currency` | Currency of debt |

## 2. List Customer Account Change Records (FP-02)

- **SDK method:** `list_customer_account_change_records`
- **REST:** `GET /v2/accounts/customer-accounts/account-change-records`
- **Auth:** GlobalCredentials (AK/SK)

| Request field | Required | Description |
|---------------|----------|-------------|
| `balance_type` | Yes | `BALANCE_TYPE_DEBIT` (cash) or `BALANCE_TYPE_CREDIT` (credit) |
| `trade_time_begin` | No | Start date of the query window (inclusive) |
| `trade_time_end` | No | End date of the query window (inclusive) |
| `offset` | No | Page offset (default 0) |
| `limit` | No | Page size — **max 100** |
| `revenue_expense_type` | No | `REVENUE` (income) / `EXPENSE` (outgo) filter |
| `trade_type` | No | `RECHARGE` / `DEDUCT` / `REFUND` / `ADJUST` / ... filter |

| Response field | Description |
|----------------|-------------|
| `total_count` | Total matching records |
| `currency` | Currency |
| `records[]` | Record list |
| `records[].trade_time` | Trade time |
| `records[].trade_id` | Trade/order ID |
| `records[].trade_detail_type` | `RECHARGE`, `DEDUCT`, `REFUND`, `ADJUST`, ... |
| `records[].change_amount` | Change amount (positive/negative) |
| `records[].balance_after_change` | Balance after this record |
| `records[].type` | Record type |
| `records[].customer_id` / `records[].account_name` | Account identifiers |

## Notes

- `limit` above 100 causes HTTP 400 for the change-records API.
- Use `trade_time_begin`/`trade_time_end` to implement the "last 6 months"
  window (default in the script is `--months 6`).
- Both APIs are read-only — no resource mutation, no confirmation needed.
