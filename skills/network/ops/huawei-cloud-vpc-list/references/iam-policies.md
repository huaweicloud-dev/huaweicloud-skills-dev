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

## Notes

- Only `list` actions are granted — no `create`, `update`, or `delete` actions.
- `vpc:vpc:list` is the VPC API permission for querying the VPC list (v3); the
  v2 API uses the same read permission.
- If the user only needs to inspect VPCs of their own project, no enterprise-project
  cross-account access is required. Listing across all enterprise projects
  (`enterprise_project_id=all_granted_eps`) requires the user to have granted
  permissions to the relevant enterprise projects.
- Use the pre-defined Huawei Cloud role `VPC ReadOnlyAccess` if a managed role
  is preferred over a custom policy.
