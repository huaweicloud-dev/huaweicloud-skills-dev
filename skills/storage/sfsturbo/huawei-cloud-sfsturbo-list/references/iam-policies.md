# IAM Policies

## Least-Privilege Policy for SFS (SFSTurbo) List

This skill only queries the SFS (Scalable File Service / SFS Turbo) file
system list. The following IAM policy grants read-only listing with least
privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sfsturbo:shares:listShares"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, the system policy `SFS Turbo ReadOnlyAccess` also works — it
includes all SFS Turbo read permissions (file systems, shared tags, perm
rules). It is broader than the least-privilege policy above, so prefer the
fine-grained action when possible.

## Notes

- This skill performs **no write operations** — all commands are read-only
- No `sfsturbo:shares:createShare`, `sfsturbo:shares:deleteShare`,
  `sfsturbo:shares:expandShare`, or other write permissions are needed
- The project ID is resolved automatically by the CLI from the authenticated profile
