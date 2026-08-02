# EIP Policies

## Least-Privilege Policy for EIP Listing

This skill is read-only and only needs permission to list and view EIPs in the target project. The minimal VPC actions are `vpc:publicIps:list` (list EIPs) and `vpc:publicIps:get` (show EIP detail).

### Policy JSON

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "vpc:publicIps:list",
        "vpc:publicIps:get"
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
resources, including `vpc:publicIps:list` and `vpc:publicIps:get`. Use it when
fine-grained policy management is not required.

### Notes

- No `vpc:publicIps:create`, `vpc:publicIps:update`, `vpc:publicIps:delete`, `vpc:publicIps:associate`, or bandwidth write actions are included — this skill never modifies resources.
- The KooCLI `hcloud EIP` commands use the credentials configured for the hcloud CLI; the EIP policy above governs what those credentials are allowed to do.
- Listing EIPs is region-scoped: the IAM policy is global, but the EIP API only returns
  EIPs of the region passed via `--cli-region`.
