# IAM Policies — huawei-cloud-vpc-list

## Least-Privilege Policy

The `huawei-cloud-vpc-list` skill is **read-only**. The minimum permission needed
to list VPCs is `vpc:vpc:list`. The recommended least-privilege IAM policy is:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "vpc:vpc:list",
        "vpc:vpcs:list"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```

## Why These Permissions

| Action | Required For | Scope |
|--------|--------------|-------|
| `vpc:vpc:list` | List VPCs via the VPC API (v3 `ListVpcs`) | All projects the user can access |
| `vpc:vpcs:list` | Compatibility action name for listing VPCs | All projects the user can access |

## Notes

- No write permissions (`vpc:vpc:create`, `vpc:vpc:update`, `vpc:vpc:delete`) are granted —
  this skill is strictly read-only.
- To list VPCs of all enterprise projects the user is granted access to, the IAM user needs
  the `all_granted_eps` scope on `vpc:vpc:list` (this is a property of the enterprise-project
  permission model, granted through the IAM user's enterprise-project authorization).
- The AK/SK used by the CLI must belong to a user with the above policy attached (directly or
  via a user group).
