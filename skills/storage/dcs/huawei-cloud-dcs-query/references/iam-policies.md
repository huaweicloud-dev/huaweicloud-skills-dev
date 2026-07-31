# IAM Policies

## Least-Privilege Policy for DCS Query

This skill requires read-only access to DCS resources. Use the following IAM policy for least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dcs:instance:list",
        "dcs:instance:get",
        "dcs:instance:getConfig",
        "dcs:instance:getSlowLog",
        "dcs:instance:getBackup",
        "dcs:instance:getRestore",
        "dcs:instance:getBigkeyScan",
        "dcs:instance:getHotkeyScan",
        "dcs:instance:getDiagnosis",
        "dcs:migration:list",
        "dcs:migration:get",
        "dcs:acl:list",
        "dcs:whitelist:get",
        "dcs:quota:get",
        "dcs:tag:list"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, assign the system policy `DCS ReadOnlyAccess` which includes all DCS read permissions.

## Notes

- This skill performs **no write operations** — all commands are read-only
- No `dcs:instance:create`, `dcs:instance:delete`, `dcs:instance:update`, or `dcs:migration:create` permissions are needed
- Slow log queries require a time range (Unix milliseconds) within a supported retention window
