# IAM Policies

Least-privilege IAM policy for listing DWS clusters.

## Required Permission

| Permission | Scope | Purpose |
|------------|-------|---------|
| `dws:cluster:list` | Project-level | Query the DWS cluster list |

## Recommended Policy JSON

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dws:cluster:list"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```

## Notes

- This skill only performs **read-only** listing; no create/delete/update permissions are required.
- For querying across enterprise projects (`all_granted_eps`), the IAM user must have the `dws:cluster:list` permission
  granted on each enterprise project, or use an IAM user with enterprise project management privileges.
- Grant via IAM → Users → Authorization, or attach the custom policy to the user group.
