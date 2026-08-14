# Dataflow Diagram

```mermaid
flowchart TD
    U[User / Agent] -->|request: balance / balance history / monthly bill| S[huawei-cloud-billing-balance-history skill]
    S -->|intent + params| W[Quality wrapper<br/>scripts/query_balance_history.py]
    W -->|quality_context start| P[huaweicloudsdkbss BssClient]
    P -->|GET /v2/accounts/customer-accounts/balances| A[Huawei Cloud BSS v2 API<br/>https://bss.myhuaweicloud.com]
    P -->|GET /v2/accounts/customer-accounts/account-change-records| A
    P -->|GET /v2/bills/customer-bills/monthly-sum| A
    A -->|balance / change records / monthly sums| P
    P --> R[Parse & build report<br/>per action]
    R -->|success / biz_fail / sys_fail| Q[skill_quality_sdk.py<br/>report to skillsopr]
    R -->|report (text or JSON)| S
    S -->|present report| U
```

## Flow Description

1. The user asks for the Huawei Cloud account balance, balance change history
   over a time period, or monthly bill summary.
2. The skill reads the AK/SK from environment variables and builds a BSS SDK
   client with `GlobalCredentials` against the global endpoint
   `https://bss.myhuaweicloud.com`.
3. Depending on the action, one of these read-only GET APIs is called:
   - `balance` → `show_customer_account_balances`
     (`GET /v2/accounts/customer-accounts/balances`)
   - `changes` → `list_customer_account_change_records`
     (`GET /v2/accounts/customer-accounts/account-change-records`, with
     `balance_type` + optional `trade_time_begin` / `trade_time_end` date range)
   - `monthly-sum` → `show_customer_monthly_sum`
     (`GET /v2/bills/customer-bills/monthly-sum`, with `bill_cycle` YYYY-MM)
4. The response is normalized into a report; account types are mapped to names
   (1=balance, 2=credit, 5=reward, 7=deposit) and Decimal amounts to numbers.
5. The quality wrapper reports the execution outcome (success/biz_fail/sys_fail,
   error code, and trace_id) to the skillsopr operations console. Reporting is
   non-blocking and fails silently.
