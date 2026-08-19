# IAM Policies

## Least-Privilege Policy for Account Revocation

The following IAM policy grants minimum permissions required to perform account permission revocation operations. Apply this policy to the operator IAM user or group.

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:users:list",
        "iam:users:get",
        "iam:users:delete",
        "iam:groups:list",
        "iam:groups:get",
        "iam:groups:delete",
        "iam:policies:list",
        "iam:policies:get",
        "iam:policies:detach",
        "iam:accessKeys:list",
        "iam:accessKeys:delete",
        "iam:loginProfiles:delete",
        "iam:virtualMfaDevices:delete",
        "iam:roles:revokeFromUser"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```

## Predefined IAM Roles

Alternatively, the following Huawei Cloud predefined roles include the necessary permissions:

| Role | Description |
|------|-------------|
| `Security Administrator` | Full IAM management permissions |
| `IAM Administrator` | Full IAM user and permission management |

> **Note:** Use the custom policy above for least-privilege access. Built-in roles grant broader permissions than needed.

## Permission Dependencies

| Operation | Required IAM Action |
|-----------|-------------------|
| List users | `iam:users:list` |
| Detach policy from user | `iam:policies:detach` |
| Detach policy from group | `iam:policies:detach` |
| Remove user from group | `iam:groups:update` |
| Delete login profile | `iam:loginProfiles:delete` |
| Delete access key | `iam:accessKeys:delete` |
| Delete MFA device | `iam:virtualMfaDevices:delete` |
| Delete group | `iam:groups:delete` |
| Delete user | `iam:users:delete` |
| Revoke role from user on EP | `iam:roles:revokeFromUser` |