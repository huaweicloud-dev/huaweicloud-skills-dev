# Verification Method

## Prerequisites

```bash
python3 --version                      # >= 3.8
python3 -c "import huaweicloudsdkbss; print('OK')"
# If missing: pip3 install --user huaweicloudsdkbss
```

## Credentials

AK/SK must be present in the environment:

```bash
export HUAWEI_ACCESS_KEY=<your-ak>
export HUAWEI_SECRET_KEY=<your-sk>
# or HUAWEICLOUD_SDK_AK / HUAWEICLOUD_SDK_SK, or HW_ACCESS_KEY / HW_SECRET_KEY
```

## Verification Steps

### 1. Balance query (FP-01)

```bash
python3 scripts/bss_balance_query.py --balance-type BALANCE_TYPE_DEBIT --months 1 --limit 5
```

Expected: JSON output containing `balance.account_balances` with `amount`,
`currency`, and optionally `credit_amount`; `change_records` with
`total_count >= 0`.

### 2. Half-year query (FP-02)

```bash
python3 scripts/bss_balance_query.py --balance-type BALANCE_TYPE_DEBIT \
  --begin $(date -d '6 months ago' +%Y-%m-%d) --end $(date +%Y-%m-%d) --limit 20
```

Expected: `query_range.begin/end` covers the last 6 months; `records[]` items
show `trade_time`, `change_amount`, `trade_detail_type`, `type`.

### 3. Automated test runner

```bash
bash scripts/test-cli-commands.sh . --executor sdk
```

Expected: all test cases in `templates/test-vars.json` PASS against the live API.

## Failure Handling

| Symptom | Cause / Fix |
|---------|-------------|
| `credentials not found` | AK/SK env vars not set — configure them first |
| `401` / `403` | Wrong AK/SK, or IAM user lacks `bss:balance:view` / `bss:bill:view` |
| `400` on change records | `limit` > 100 — BSS caps page size at 100; lower `--limit` |
| `GlobalCredentials` import error | huaweicloudsdkcore too old — `pip3 install -U huaweicloudsdkcore huaweicloudsdkbss` |
