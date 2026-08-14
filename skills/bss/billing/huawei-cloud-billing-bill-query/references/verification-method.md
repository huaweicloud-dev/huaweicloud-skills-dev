# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/bss/billing/huawei-cloud-billing-bill-query
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### SDK Mode

```bash
bash scripts/test-cli-commands.sh skills/bss/billing/huawei-cloud-billing-bill-query sdk
```

Test parameters are read from `templates/test-vars.json`. The environment
variables `HUAWEI_ACCESS_KEY` / `HUAWEI_SECRET_KEY` (or
`HUAWEICLOUD_SDK_AK` / `HUAWEICLOUD_SDK_SK`) provide the credentials.

### Direct Script Runs

```bash
# Bill fee records for the current month (text report, default action)
python3 scripts/query_bills.py

# Bill fee records for a specific month (JSON)
python3 scripts/query_bills.py --action fee-records --bill-cycle 2026-07 --format json

# Resource fee records (流水账单) for one month
python3 scripts/query_bills.py --action res-fee-records --cycle 2026-07

# Monthly cost breakdown for a shared month
python3 scripts/query_bills.py --action breakdown --shared-month 2026-07

# Narrow to a date range within the month
python3 scripts/query_bills.py --action res-fee-records --cycle 2026-07 \
  --bill-date-begin 2026-07-01 --bill-date-end 2026-07-31

# With reporting disabled (local debug)
SKILL_QUALITY_DISABLE=1 python3 scripts/query_bills.py --action fee-records --bill-cycle 2026-07
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | Query fee records (text) | `python3 scripts/query_bills.py --action fee-records --bill-cycle <YYYY-MM>` |
| 2 | Query fee records (JSON) | `python3 scripts/query_bills.py --action fee-records --bill-cycle <YYYY-MM> --format json` |
| 3 | Query resource fee records | `python3 scripts/query_bills.py --action res-fee-records --cycle <YYYY-MM>` |
| 4 | Query monthly breakdown | `python3 scripts/query_bills.py --action breakdown --shared-month <YYYY-MM>` |
| 5 | Invalid cycle rejected | `python3 scripts/query_bills.py --action fee-records --bill-cycle 2026/07` → exits 1 with `U02` |
| 6 | Missing AK/SK handled | `env -u HUAWEI_ACCESS_KEY -u HUAWEI_SECRET_KEY python3 scripts/query_bills.py` → exits 1 with `C01` |
| 7 | Cross-month date range rejected | `python3 scripts/query_bills.py --action fee-records --bill-cycle 2026-07 --bill-date-begin 2026-06-20 --bill-date-end 2026-07-10` → exits 1 with `U02` (date outside billing cycle) |
| 8 | limit out of range rejected | `python3 scripts/query_bills.py --action fee-records --bill-cycle 2026-07 --limit 0` → exits 1 with `U02` (must be 1-100) |
| 9 | Action/param mismatch rejected | `python3 scripts/query_bills.py --action fee-records --shared-month 2026-07` → exits 1 with `U02`; `python3 scripts/query_bills.py --action breakdown --shared-month 2026-07 --bill-date-begin 2026-07-01` → exits 1 with `U02` |
| 10 | Quality reporting disabled | `SKILL_QUALITY_DISABLE=1 python3 scripts/query_bills.py --action fee-records --bill-cycle <YYYY-MM>` |

## Expected Results

- `fee-records`: HTTP 200 with `total_count`, `currency` (e.g. `CNY`) and
  `records[]` containing `consume_time`, `service_type_name`,
  `resource_name`, `consume_amount`, `cash_amount`, `coupon_amount`, etc.
- `res-fee-records`: HTTP 200 with `total_count`, `currency` and
  `records[]` containing `bill_date`, `cloud_service_type_name`,
  `resource_name`, `amount`, `cash_amount`, etc.
- `breakdown`: HTTP 200 with `total_count`, `currency` and `details[]`
  containing `service_type_name`, `resource_name`, `consume_amount`,
  `current_month_amortized_amount`, etc.
- All three actions are read-only GET queries scoped to a single billing
  cycle and never mutate billing data.
