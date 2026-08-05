# IAM Policies

## Least-Privilege Policy for RDS Troubleshooting

This skill performs read-only diagnostics (instance list/detail, replication
status, storage usage, slow/error logs, configurations, backups, intelligent
diagnosis) plus user-confirmed write operations (restart, parameter modify,
manual backup, restore). The least-privilege policy below covers the
read-only diagnostic surface; write operations require the additional
actions in the second statement.

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:instance:list",
        "rds:instance:get",
        "rds:backup:list",
        "rds:backup:get",
        "rds:configuration:list",
        "rds:configuration:get",
        "rds:log:list"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "rds:instance:action",
        "rds:backup:create",
        "rds:configuration:update"
      ],
      "Resource": ["*"],
      "Condition": {
        "StringEquals": {
          "rds:RequestTag/usage": "troubleshoot-confirmed"
        }
      }
    }
  ]
}
```

> **Note:** The exact IAM action strings for RDS follow the
> `rds:<resource>:<verb>` convention (e.g. `rds:instance:list`). If a
> specific action name is rejected by IAM in your environment, grant the
> corresponding system policy instead (below). The write statement is the
> minimum needed for the confirmed-write operations in this skill; you may
> drop it entirely for read-only usage.

## Alternative: System Policies

For convenience, Huawei Cloud provides two system policies for RDS:

| Policy | Scope | Recommended for |
|--------|-------|-----------------|
| `RDS ReadOnlyAccess` | All RDS read permissions (instance, backup, configuration, log query) | Read-only diagnosis & troubleshooting (default) |
| `RDS FullAccess` | All RDS read + write permissions | Troubleshooting that includes confirmed restarts / parameter changes / backups / restore |

Prefer `RDS ReadOnlyAccess` for the common fault-diagnosis flow, and only
grant `RDS FullAccess` (or the fine-grained write actions) when the user has
confirmed a write operation is needed.

## Notes

- This skill performs **no instance create/delete** and **no DDL/DML** —
  `rds:instance:create`, `rds:instance:delete`, and database-user management
  actions are intentionally absent.
- Write operations (restart, parameter modify, manual backup, restore) are
  **only executed after explicit user confirmation**.
- The project ID is resolved automatically by the CLI from the authenticated
  profile.
- No credentials (AK/SK) are hardcoded anywhere in this skill; they are read
  from environment variables (`HUAWEI_ACCESS_KEY` / `HUAWEI_SECRET_KEY` or
  `HUAWEICLOUD_SDK_AK` / `HUAWEICLOUD_SDK_SK`) or the `hcloud configure`
  profile.
