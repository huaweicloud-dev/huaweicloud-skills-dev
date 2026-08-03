# IAM Policies

## Least-Privilege Policy for CSS Cluster List

This skill requires read-only access to CSS (Cloud Search Service) resources. Use the following IAM policy for least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "css:cluster:list",
        "css:cluster:get"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, assign the system policy `CSS ReadOnlyAccess`, which includes all CSS read permissions.

## Notes

- This skill performs **no write operations** — all commands are read-only
- No `css:cluster:create`, `css:cluster:delete`, `css:cluster:modify`, or other write permissions are needed
- The cluster list query is scoped to the project; the project ID is resolved automatically by the CLI
- If the user cannot find the CSS cluster list, verify the IAM user has `CSS ReadOnlyAccess` (or `css:cluster:list`) in the target project
