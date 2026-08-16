# IAM Policies — Least Privilege for DDS Instance Listing

This skill only **lists** DDS instances (`hcloud DDS ListInstances` / SDK
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
        "dds:instance:list"
      ],
      "Resource": [
        "dds:instance:*"
      ]
    }
  ]
}
```

> The DDS IAM actions follow the `dds:<resource>:<verb>` convention. The
> read-only action required for listing instances is `dds:instance:list`.

## System policy (convenient alternative)

| Policy | Permissions | Use case |
|--------|-------------|----------|
| `DDS ReadOnlyAccess` | All DDS read permissions (instance, backup, configuration, log query) | Read-only listing & inspection (default) |
| `DDS FullAccess` | All DDS read + write permissions | **Not needed** for this skill — avoid granting write access |

Prefer `DDS ReadOnlyAccess` for the common listing flow. Never grant
`DDS FullAccess` unless the user explicitly needs write operations (which this
skill does not perform).

## Credential notes

- The skill reads AK/SK from environment variables
  (`HUAWEI_ACCESS_KEY` / `HUAWEI_SECRET_KEY`, or
  `HUAWEICLOUD_SDK_AK` / `HUAWEICLOUD_SDK_SK`).
- Never hardcode credentials in scripts or configuration files.
- Use a dedicated IAM user (or agency) with only the read-only DDS policy above.
