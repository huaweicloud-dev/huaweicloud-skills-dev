# IAM Policies

## Least-Privilege Policy for SWR Repository List

This skill requires read-only access to SWR (Software Repository for Container) resources. Use the following IAM policy for least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "swr:repository:list",
        "swr:repository:get"
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
- No `swr:repository:create`, `swr:repository:update`, `swr:repository:delete`, or other write permissions are needed
- The repository list query is scoped to the project; the project ID is resolved automatically by the CLI
- If the user cannot find the SWR repository list, verify the IAM user has `SWR ReadOnlyAccess` (or `swr:repository:list`) in the target project
