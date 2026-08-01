# IAM Policies

## Least-Privilege Policy for IAM User Listing

This skill is read-only and only needs permission to list IAM users under the account. The minimal IAM action is `iam:users:listUsers`.

### Policy JSON

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:users:listUsers"
      ],
      "Resource": [
        "IAM:*:*:user:*"
      ]
    }
  ]
}
```

### Alternative: Predefined Role

Huawei Cloud provides the `IAM ReadOnlyAccess` role which grants read-only access to IAM users, groups, and policies,
including `iam:users:listUsers`. Use it when fine-grained policy management is not required.

### Notes

- No `iam:users:createUser`, `iam:users:updateUser`, `iam:users:deleteUser`, or other write actions are included — this skill never modifies resources.
- The KooCLI `hcloud IAM` commands use the credentials configured for the hcloud CLI; the IAM policy above governs what those credentials are allowed to do.
