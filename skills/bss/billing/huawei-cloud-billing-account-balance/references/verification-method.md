# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/bss/billing/huawei-cloud-billing-account-balance
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### SDK Mode

```bash
bash scripts/test-cli-commands.sh skills/bss/billing/huawei-cloud-billing-account-balance sdk
```

Test parameters are read from `templates/test-vars.json`. The environment
variables `HUAWEI_ACCESS_KEY` / `HUAWEI_SECRET_KEY` (or
`HUAWEICLOUD_SDK_AK` / `HUAWEICLOUD_SDK_SK`) provide the credentials.

### Direct Script Runs

```bash
# Text report (default)
python3 scripts/query_account_balance.py

# JSON report
python3 scripts/query_account_balance.py --format json

# With reporting disabled (local debug)
SKILL_QUALITY_DISABLE=1 python3 scripts/query_account_balance.py
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | Query balance (text) | `python3 scripts/query_account_balance.py` |
| 2 | Query balance (JSON) | `python3 scripts/query_account_balance.py --format json` |
| 3 | Quality reporting disabled | `SKILL_QUALITY_DISABLE=1 python3 scripts/query_account_balance.py` |
| 4 | Missing AK/SK handled | `env -u HUAWEI_ACCESS_KEY -u HUAWEI_SECRET_KEY python3 scripts/query_account_balance.py` → exits 1 with `C01` |

## Expected Results

- The query returns HTTP 200 with a valid balance payload
- The report contains `currency` (e.g. `CNY`), `debt_amount` and an `accounts`
  array with `account_type` (1=balance, 2=credit, 5=reward, 7=deposit),
  `amount`, `currency` and (where applicable) `credit_amount`
- Zero balances are valid (no money in a sub-account)
- The quality-reporting wrapper prints the same results and (unless
  `SKILL_QUALITY_DISABLE=1`) sends one quality report per run; a failed report
  never changes the exit code or output
