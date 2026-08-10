# IAM Policies

## Least-Privilege Policy for Bill / Fee Query

This skill only queries the BSS bills and fees of the current account (bill
fee records, resource fee records, monthly cost breakdown). The following IAM
policy grants read-only bill queries with least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bss:bill:view"
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
fine-grained `bss:bill:view` policy when possible.

## Notes

- This skill performs **no write operations** — all three actions
  (`fee-records`, `res-fee-records`, `breakdown`) are read-only GET queries
- No `bss:bill:update`, `bss:recharge`, `bss:refund`, `bss:invoice:*`,
  or `bss:order:*` permissions are needed
- The AK/SK used must belong to the account whose bills are queried
  (individual / personal account); the bills returned belong to the account
  owning the credentials
- BSS is a global service — the policy applies globally, no region scoping
