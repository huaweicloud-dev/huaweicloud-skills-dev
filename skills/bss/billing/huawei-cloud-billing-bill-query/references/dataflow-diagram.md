# Dataflow Diagram

```mermaid
flowchart TD
    U[User / Agent] -->|request: bills / fees / 流水账单 / monthly cost| S[huawei-cloud-billing-bill-query skill]
    S -->|intent + params| W[Quality wrapper<br/>scripts/query_bills.py]
    W -->|quality_context start| P[huaweicloudsdkbss BssClient]
    P -->|GET /v2/bills/customer-bills/fee-records| A[Huawei Cloud BSS v2 API<br/>https://bss.myhuaweicloud.com]
    P -->|GET /v2/bills/customer-bills/res-fee-records| A
    P -->|GET /v2/costs/cost-analysed-bills/monthly-breakdown| A
    A -->|fee records / resource fee records / breakdown| P
    P --> R[Parse & build report<br/>per action]
    R -->|success / biz_fail / sys_fail| Q[skill_quality_sdk.py<br/>report to skillsopr]
    R -->|report (text or JSON)| S
    S -->|present report| U
```

## Flow Description

1. The user asks for the Huawei Cloud account's bills / fees / 流水账单 /
   monthly cost within one billing cycle (month).
2. The skill reads the AK/SK from environment variables and builds a BSS SDK
   client with `GlobalCredentials` against the global endpoint
   `https://bss.myhuaweicloud.com`.
3. Depending on the action, one of these read-only GET APIs is called with a
   single billing cycle (`YYYY-MM`, default = current month):
   - `fee-records` → `list_customer_bills_fee_records`
     (`GET /v2/bills/customer-bills/fee-records`, with `bill_cycle`)
   - `res-fee-records` → `list_customerself_resource_records`
     (`GET /v2/bills/customer-bills/res-fee-records`, with `cycle`)
   - `breakdown` → `list_customer_bills_monthly_break_down`
     (`GET /v2/costs/cost-analysed-bills/monthly-breakdown`, with
     `shared_month`)
4. The response is normalized into a report; SDK Decimal amounts are converted
   to numbers for JSON output.
5. The quality wrapper reports the execution outcome (success/biz_fail/sys_fail,
   error code, and trace_id) to the skillsopr operations console. Reporting is
   non-blocking and fails silently.
