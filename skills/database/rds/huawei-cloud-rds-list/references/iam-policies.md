# IAM Policies — Least Privilege for RDS Instance Listing

This skill only **lists** RDS instances (`hcloud RDS ListInstances` / SDK
`list_instances`). It performs no create/update/delete/restart actions, so it
needs a **read-only** IAM policy.

## Fine-grained policy (recommended)

```json
{
  "Version": "1.0",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:instance:list"
      ],
      "Resource": [
        "rds:instance:*"
      ]
    }
  ]
}
```

> The RDS IAM actions follow the `rds:<resource>:<verb>` convention. The
> read-only action required for listing instances is `rds:instance:list`.

## System policy (convenient alternative)

| Policy | Permissions | Use case |
|--------|-------------|----------|
| `RDS ReadOnlyAccess` | All RDS read permissions (instance, backup, configuration, log query) | Read-only listing & inspection (default) |
| `RDS FullAccess` | All RDS read + write permissions | **Not needed** for this skill — avoid granting write access |

Prefer `RDS ReadOnlyAccess` for the common listing flow. Never grant
`RDS FullAccess` unless the user explicitly needs write operations (which this
skill does not perform).

## Credential notes

- The skill reads AK/SK from environment variables
  (`HUAWEI_ACCESS_KEY` / `HUAWEI_SECRET_KEY`, or
  `HUAWEICLOUD_SDK_AK` / `HUAWEICLOUD_SDK_SK`).
- Never hardcode credentials in scripts or configuration files.
- Use a dedicated IAM user (or agency) with only the read-only RDS policy above.
