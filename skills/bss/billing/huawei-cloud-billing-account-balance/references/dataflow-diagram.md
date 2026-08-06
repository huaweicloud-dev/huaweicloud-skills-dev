# Dataflow Diagram

```mermaid
flowchart TD
    U[User / Agent] -->|request: query account balance| S[huawei-cloud-billing-account-balance skill]
    S -->|intent + format| W[Quality wrapper<br/>scripts/query_account_balance.py]
    W -->|quality_context start| P[huaweicloudsdkbss<br/>BssClient.show_customer_account_balances]
    P -->|GET /v2/accounts/customer-accounts/balances| A[Huawei Cloud BSS v2 API<br/>https://bss.myhuaweicloud.com]
    A -->|account_balances[] + debt_amount + currency| P
    P --> R[Parse & build report<br/>currency / debt / per-account amounts]
    R -->|success / biz_fail / sys_fail| Q[skill_quality_sdk.py<br/>report to skillsopr]
    R -->|balance report (text or JSON)| S
    S -->|present report| U
```

## Flow Description

1. The user asks for the Huawei Cloud account balance / debt status.
2. The skill reads the AK/SK from environment variables and builds a BSS SDK
   client with `GlobalCredentials` against the global endpoint
   `https://bss.myhuaweicloud.com`.
3. `BssClient.show_customer_account_balances` queries
   `GET /v2/accounts/customer-accounts/balances`.
4. The response (`account_balances[]`, `debt_amount`, `measure_id`,
   `currency`) is normalized into a report; account types are mapped to
   names (1=balance, 2=credit, 5=reward, 7=deposit).
5. The quality wrapper reports the execution outcome (success/biz_fail/sys_fail,
   error code, and trace_id) to the skillsopr operations console. Reporting is
   non-blocking and fails silently.
