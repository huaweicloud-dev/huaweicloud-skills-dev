# VPC Policies

## Least-Privilege Policy for Security Group Listing

This skill is read-only and only needs permission to list security groups in the target project. The minimal VPC action is `vpc:securityGroups:list`.

### Policy JSON

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "vpc:securityGroups:list"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```

### Alternative: Predefined Role

Huawei Cloud provides the `VPC ReadOnlyAccess` role which grants read-only access to VPC
resources, including `vpc:securityGroups:list` and `vpc:securityGroups:get`. Use it when
fine-grained policy management is not required.

### Notes

- No `vpc:securityGroups:create`, `vpc:securityGroups:update`, `vpc:securityGroups:delete`, or `vpc:securityGroupRules:*` write actions are included — this skill never modifies resources.
- The KooCLI `hcloud VPC` commands use the credentials configured for the hcloud CLI; the VPC policy above governs what those credentials are allowed to do.
- Listing security groups is region-scoped: the IAM policy is global, but the VPC API only returns
  security groups of the region passed via `--cli-region`.
