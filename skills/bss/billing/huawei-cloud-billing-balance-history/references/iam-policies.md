# IAM Policies

## Least-Privilege Policy for Balance / Bill History Query

This skill only queries the BSS customer account balance, balance change
records, and monthly bill summary. The following IAM policy grants read-only
billing queries with least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bss:balance:view"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, the system policy `BSS ReadOnlyAccess` also works — it
includes all BSS read permissions (balances, bills, orders, coupons, etc.).
It is broader than the least-privilege policy above, so prefer the
fine-grained `bss:balance:view` policy when possible.

## Notes

- This skill performs **no write operations** — all three actions
  (`balance`, `changes`, `monthly-sum`) are read-only GET queries
- No `bss:balance:update`, `bss:recharge`, `bss:refund`, `bss:invoice:*`,
  or `bss:order:*` permissions are needed
- The AK/SK used must belong to the account whose balance is queried
  (individual / personal account); the balance returned is the balance of the
  account owning the credentials
- Balance change records (`changes`) and monthly summaries (`monthly-sum`)
  are also covered by the BSS read permissions above; if your organization
  restricts bill viewing, additionally grant `bss:bill:view` (included in
  `BSS ReadOnlyAccess`)
