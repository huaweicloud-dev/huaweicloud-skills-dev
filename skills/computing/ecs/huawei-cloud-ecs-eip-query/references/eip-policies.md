# EIP and ECS Policies

## Least-Privilege Policy for ECS EIP Query

This skill is read-only and needs permission to list and view EIPs, plus read-only ECS access to resolve an ECS
name to its ID and to confirm bindings. The minimal VPC actions are `vpc:publicIps:list` (list EIPs) and
`vpc:publicIps:get` (show EIP detail); the minimal ECS actions are `ecs:servers:list` (list servers by name)
and `ecs:servers:get` (show server detail).

### Policy JSON

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "vpc:publicIps:list",
        "vpc:publicIps:get",
        "ecs:servers:list",
        "ecs:servers:get"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```

### Alternative: Predefined Roles

Huawei Cloud provides the `VPC ReadOnlyAccess` role (grants `vpc:publicIps:list` and `vpc:publicIps:get`)
and the `ECS ReadOnlyAccess` role (grants `ecs:servers:list` and `ecs:servers:get`). Assign both when
fine-grained policy management is not required.

### Notes

- No `vpc:publicIps:create`, `vpc:publicIps:update`, `vpc:publicIps:delete`, `vpc:publicIps:associate`,
  `ecs:servers:create` or other write actions are included — this skill never modifies resources.
- The KooCLI `hcloud EIP` and `hcloud ECS` commands use the credentials configured for the hcloud CLI;
  the policies above govern what those credentials are allowed to do.
- Listing EIPs is region-scoped: the IAM policy is global, but the EIP API only returns
  EIPs of the region passed via `--cli-region`.
