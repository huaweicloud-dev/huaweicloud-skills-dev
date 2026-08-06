# IAM Policies

## Least-Privilege Policy for SWR Namespace List

This skill requires read-only access to SWR (Software Repository for Container) namespace resources. Use the following IAM policy for least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "swr:namespace:list",
        "swr:namespace:get"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, assign the system policy `SWR ReadOnlyAccess`, which includes all SWR read permissions (namespaces, repositories, tags, quotas).

## Notes

- This skill performs **no write operations** — all commands are read-only
- No `swr:namespace:create`, `swr:namespace:delete`, or other write permissions are needed
- The namespace list query is scoped to the project; the project ID is resolved automatically by the CLI
- If the user cannot find the SWR namespace list, verify the IAM user has `SWR ReadOnlyAccess` (or `swr:namespace:list`) in the target project
