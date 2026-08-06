# IAM Policies

## Least-Privilege Policy for BMS List

This skill only queries the BMS (Bare Metal Server) list. The following IAM
policy grants read-only server listing with least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bms:servers:list"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, the system policy `BMS ReadOnlyAccess` also works — it
includes all BMS read permissions (server, flavor, and other resources). It is
broader than the least-privilege policy above, so prefer the fine-grained
`bms:servers:list` policy when possible.

## Notes

- This skill performs **no write operations** — all commands are read-only
- No `bms:servers:create`, `bms:servers:delete`, `bms:servers:update`, or
  volume/NIC management permissions are needed
- The project ID is resolved automatically by the CLI from the authenticated profile
