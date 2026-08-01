# IAM Policies

## Least-Privilege Policy for Project Listing

This skill is read-only and only needs permission to list projects under the account. The minimal IAM action is `iam:projects:listProjects`.

### Policy JSON

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:projects:listProjects"
      ],
      "Resource": [
        "IAM:*:*:project:*"
      ]
    }
  ]
}
```

### Alternative: Predefined Role

Huawei Cloud provides the `IAM ReadOnlyAccess` role which grants read-only access to IAM users, groups, projects, and policies,
including `iam:projects:listProjects`. Use it when fine-grained policy management is not required.

### Notes

- No `iam:projects:createProject`, `iam:projects:updateProject`, `iam:projects:deleteProject`, or other write actions are included — this skill never modifies resources.
- The KooCLI `hcloud IAM` commands use the credentials configured for the hcloud CLI; the IAM policy above governs what those credentials are allowed to do.
