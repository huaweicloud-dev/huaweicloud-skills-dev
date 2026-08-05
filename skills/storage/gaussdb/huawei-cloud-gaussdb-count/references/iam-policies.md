# IAM Policies

## Least-Privilege Policy for GaussDB Count

This skill requires read-only access to GaussDB instances. Use the following IAM policy for least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "gaussdb:instance:list"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, assign the system policy `GaussDB ReadOnlyAccess`, which includes all GaussDB read permissions.

## Notes

- This skill performs **no write operations** — all commands are read-only
- No `gaussdb:instance:create`, `gaussdb:instance:delete`, `gaussdb:instance:modify`, or other write permissions are needed
- Instance list queries require the project ID of the target project; it is resolved automatically by the CLI
- The same read-only policy applies to both `GaussDBforopenGauss` (openGauss) and `GaussDB` (MySQL-compatible) services
