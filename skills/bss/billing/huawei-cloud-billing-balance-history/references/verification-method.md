# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/bss/billing/huawei-cloud-billing-balance-history
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### SDK Mode

```bash
bash scripts/test-cli-commands.sh skills/bss/billing/huawei-cloud-billing-balance-history sdk
```

Test parameters are read from `templates/test-vars.json`. The environment
variables `HUAWEI_ACCESS_KEY` / `HUAWEI_SECRET_KEY` (or
`HUAWEICLOUD_SDK_AK` / `HUAWEICLOUD_SDK_SK`) provide the credentials.

### Direct Script Runs

```bash
# Current account balance (text report, default)
python3 scripts/query_balance_history.py --action balance

# Balance change records in a date range (e.g. last 30 days)
python3 scripts/query_balance_history.py --action changes \
  --begin 2026-07-01 --end 2026-07-31

# Monthly consumption summary for a billing cycle
python3 scripts/query_balance_history.py --action monthly-sum --bill-cycle 2026-07

# JSON report
python3 scripts/query_balance_history.py --action balance --format json

# With reporting disabled (local debug)
SKILL_QUALITY_DISABLE=1 python3 scripts/query_balance_history.py --action balance
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | Query balance (text) | `python3 scripts/query_balance_history.py --action balance` |
| 2 | Query balance (JSON) | `python3 scripts/query_balance_history.py --action balance --format json` |
| 3 | Query changes in date range | `python3 scripts/query_balance_history.py --action changes --begin <30-days-ago> --end <today>` |
| 4 | Query monthly summary | `python3 scripts/query_balance_history.py --action monthly-sum --bill-cycle <last-month YYYY-MM>` |
| 5 | Invalid bill_cycle rejected | `python3 scripts/query_balance_history.py --action monthly-sum --bill-cycle 2026/07` → exits 1 with `U02` |
| 6 | Missing AK/SK handled | `env -u HUAWEI_ACCESS_KEY -u HUAWEI_SECRET_KEY python3 scripts/query_balance_history.py` → exits 1 with `C01` |
| 7 | Quality reporting disabled | `SKILL_QUALITY_DISABLE=1 python3 scripts/query_balance_history.py --action balance` |

## Expected Results

- `balance`: HTTP 200 with currency (e.g. `CNY`), `debt_amount` and an
  `accounts` array with `account_type` (1=balance, 2=credit, 5=reward,
  7=deposit), `amount`, `currency` and (where applicable) `credit_amount`
- `changes`: HTTP 200 with `total_count` and `records[]` containing
  `trade_time`, `revenue_expense_type`, `change_amount`, `balance_after_change`
- `monthly-sum`: HTTP 200 with `consume_amount`, `debt_amount`, `currency` and
  `bill_sums[]` per service/region
- All three actions are read-only GET queries and never mutate billing data
