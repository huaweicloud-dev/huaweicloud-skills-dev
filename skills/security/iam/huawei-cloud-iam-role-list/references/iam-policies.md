# IAM Policies

## Least-Privilege Policy for IAM Role Listing

This skill is read-only and only needs permission to list IAM roles under the account. The minimal IAM action is `iam:roles:listRoles`.

### Policy JSON

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:roles:listRoles"
      ],
      "Resource": [
        "IAM:*:*:role:*"
      ]
    }
  ]
}
```

### Alternative: Predefined Role

Huawei Cloud provides the `IAM ReadOnlyAccess` role which grants read-only access to IAM users, groups, and roles,
including `iam:roles:listRoles`. Use it when fine-grained policy management is not required.

### Notes

- No `iam:roles:createRole`, `iam:roles:updateRole`, `iam:roles:deleteRole`, or other write actions are included — this skill never modifies resources.
- The KooCLI `hcloud IAM` commands use the credentials configured for the hcloud CLI; the IAM policy above governs what those credentials are allowed to do.
