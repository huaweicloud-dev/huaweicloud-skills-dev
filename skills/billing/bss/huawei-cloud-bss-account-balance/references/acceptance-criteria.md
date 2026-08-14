# Acceptance Criteria

## Correct Patterns

✅ Query balance successfully:

```json
{
  "balance": {
    "account_balances": [
      {"account_type": "BALANCE_TYPE_DEBIT", "amount": "123.45", "currency": "CNY"}
    ],
    "debt_amount": "0"
  }
}
```

✅ Query change records over the last 6 months:

```json
{
  "query_range": {"begin": "2026-02-10", "end": "2026-08-10"},
  "change_records": {
    "total_count": 12,
    "records": [
      {"trade_time": "2026-07-01T10:00:00Z", "trade_detail_type": "RECHARGE", "change_amount": "100.00"}
    ]
  }
}
```

✅ Response is a combined JSON with both `balance` and `change_records` blocks.

## Error Patterns

❌ Credentials missing → script exits with `credentials not found` and a clear
   prompt to configure AK/SK environment variables. Do NOT continue.

❌ `--begin` given without `--end` (or vice versa) → readable error
   `--begin and --end must be provided together`, exit code 1. No silent
   fallback to the default window.

❌ Invalid input (`--balance-type FOOBAR`, `--limit 500`, malformed date,
   `--begin > --end`, `--months 0`) → readable `Error:` message on stderr,
   exit code 1. No raw traceback.

❌ IAM permission denied (`403`) → readable `BSS API error` with
   `code=..., message=...` plus a hint to check `bss:balance:view` /
   `bss:bill:view` (see `references/iam-policies.md`). No raw traceback.

❌ `400` on change records query → the BSS `limit` parameter must be ≤ 100;
   the script rejects `--limit > 100` up front with a hint.

❌ Never print AK/SK values, never accept AK/SK from the conversation, never
   hardcode credentials in scripts or documents.

## Feature Coverage

| Feature point | Acceptance |
|---------------|------------|
| FP-01 Query current balance | `balance.account_balances[].amount` and `currency` returned |
| FP-02 Query last-6-months records | `query_range` covers the window; `change_records.total_count` returned; records include trade time/amount/type |
