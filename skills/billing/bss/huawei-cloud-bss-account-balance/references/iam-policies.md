# IAM Permission Policies

Least-privilege IAM policies for the `huawei-cloud-bss-account-balance` skill.
Both feature points are **read-only** queries of the account balance and the
account change records; no write permission is required.

## Required Permissions

| Permission | Scope | Purpose |
|-----------|-------|---------|
| `bss:balance:view` | Account | Query current account balance (FP-01) |
| `bss:bill:view` | Account | Query account change records / income-expense details (FP-02) |

## Recommended Policy JSON

```json
{
  "Version": "1.0",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bss:balance:view",
        "bss:bill:view"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```

## Notes

- The BSS customer APIs (`/v2/accounts/customer-accounts/balances` and
  `/v2/accounts/customer-accounts/account-change-records`) are **global**
  APIs — no region-scoped resource is involved.
- If the account is an IAM user under an enterprise master account, the
  balance queried is the balance of the IAM user's own account. Use
  `BALANCE_TYPE_CREDIT` to also see credit-account data where applicable.
- Never grant `bss:*` write actions (`bss:balance:update`, `bss:order:update`,
  etc.) for this skill; only read permissions are needed.
- Do NOT hardcode AK/SK anywhere; credentials are read from environment
  variables only.
