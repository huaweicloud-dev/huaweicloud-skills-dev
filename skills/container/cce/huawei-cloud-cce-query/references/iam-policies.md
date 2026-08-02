# IAM Policies

## Least-Privilege Policy for CCE Query

This skill requires read-only access to CCE resources. Use the following IAM policy for least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cce:cluster:get",
        "cce:cluster:list",
        "cce:node:get",
        "cce:node:list"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, assign the system policy `CCE ReadOnlyAccess`, which includes all CCE read permissions.

## Notes

- This skill performs **no write operations** — all commands are read-only
- No `cce:cluster:create`, `cce:cluster:delete`, `cce:cluster:update`, or node create/update/delete permissions are needed
- Cluster list queries require the project ID of the target project; it is resolved automatically by the CLI
