# IAM Policies

## Least-Privilege Policy for DCS List

This skill requires read-only access to DCS resources. Use the following IAM policy for least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dcs:instance:get",
        "dcs:instance:list"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, assign the system policy `DCS ReadOnlyAccess`, which includes all DCS read permissions.

## Notes

- This skill performs **no write operations** — all commands are read-only
- No `dcs:instance:create`, `dcs:instance:delete`, `dcs:instance:modify`, or other write permissions are needed
- Instance list queries require the project ID of the target project; it is resolved automatically by the CLI
