# IAM Permission Policies

## Minimum Required Permission

The IAM user (or the account's user group) must have at least the following permission to list backups:

```json
{
  "Version": "1.0",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cbr:backups:list"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```

## Least-Privilege Notes

- The `huawei-cloud-vbs-list` skill is **read-only**: it only lists backups. Granting `cbr:backups:list` is sufficient.
- Do **not** grant write/delete actions (`cbr:backups:delete`, `cbr:backups:restore`, `cbr:vaults:create`, etc.) when the only goal is listing backups.
- If the user also needs vault / policy visibility (e.g., resolving a `vault_id` to a vault name), optionally add:
  - `cbr:vaults:list`

## Recommended Policy for Common Use

```json
{
  "Version": "1.0",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cbr:backups:list",
        "cbr:vaults:list"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```

## Attaching the Policy

1. In the IAM console, create a custom policy with the JSON above.
2. Attach it to the user group or the user that runs the skill.
3. Note: permission changes may take a few minutes to take effect.

## Cross-Check with CLI/SDK

The Huawei Cloud CBR `ListBackups` API (`GET /v3/{project_id}/backups`) maps to the IAM action
`cbr:backups:list`. If you receive a 403 "Insufficient permissions" error when running the command,
verify this policy is attached.
