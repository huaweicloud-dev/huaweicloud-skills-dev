# IAM Policies

## Least-Privilege Policy for CCE Cluster List

This skill only queries the CCE cluster list. The following IAM policy grants
read-only cluster listing with least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cce:cluster:list"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, the system policy `CCE ReadOnlyAccess` also works — it includes
all CCE read permissions (cluster, node, and other resources). It is broader than
the least-privilege policy above, so prefer the fine-grained `cce:cluster:list`
policy when possible.

## Notes

- This skill performs **no write operations** — all commands are read-only
- No `cce:cluster:create`, `cce:cluster:delete`, `cce:cluster:update`, or
  node/node-pool permissions are needed
- The project ID is resolved automatically by the CLI from the authenticated profile
