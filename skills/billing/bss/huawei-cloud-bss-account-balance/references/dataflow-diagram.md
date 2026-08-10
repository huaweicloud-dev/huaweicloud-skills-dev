# Data Flow Diagram

```mermaid
flowchart TD
    A[User / Agent request] -->|"华为云账号余额 / 近半年流水"| B[bss_balance_query.py]
    B --> C{Read credentials from env}
    C -->|"HUAWEI_ACCESS_KEY / HUAWEI_SECRET_KEY"| D[GlobalCredentials + BSS endpoint]
    C -->|missing| E[Prompt user to configure AK/SK]
    D --> F[BssClient]
    F --> G["show_customer_account_balances (GET /v2/accounts/customer-accounts/balances)"]
    F --> H["list_customer_account_change_records (GET /v2/accounts/customer-accounts/account-change-records)"]
    G --> I[Current balance: amount / currency / credit_amount / debt]
    H --> J[Change records: trade_time / change_amount / type / total_count]
    I --> K[Combined JSON summary]
    J --> K
    K --> L[Feedback to user]
    K --> M[skill_quality_sdk.py non-blocking quality report]
```

## Flow Description

1. The agent receives a request such as "查询华为云账号余额" or "查一下近半年收支明细".
2. `scripts/bss_balance_query.py` loads AK/SK from environment variables
   (`HUAWEI_ACCESS_KEY`/`HUAWEI_SECRET_KEY`, or `HUAWEICLOUD_SDK_AK`/`HUAWEICLOUD_SDK_SK`,
   or `HW_ACCESS_KEY`/`HW_SECRET_KEY`).
3. A BSS client is built with `GlobalCredentials` and the global endpoint
   `https://bss.myhuaweicloud.com` (BSS is a global service).
4. Two read-only calls are made:
   - `show_customer_account_balances` — current account balance (FP-01).
   - `list_customer_account_change_records` — income/expense records in the
     configured window (default last 6 months, FP-02).
5. The combined summary (balance + change records) is returned to the user;
   every run also emits a non-blocking quality report via the vendored
   `scripts/skill_quality_sdk.py`.
