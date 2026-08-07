# IAM Policies for huawei-cloud-obs-list-folders

This skill only **lists** OBS buckets and folder names. It never creates,
modifies or deletes buckets, folders or objects. Use the **least-privilege**
IAM policies below.

## Recommended System Policy

The managed policy **`OBS ReadOnlyAccess`** covers all read-only OBS
operations and is the simplest least-privilege choice:

```json
{
  "Version": "1.0",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "obs:*:List*",
        "obs:*:Get*",
        "obs:*:Head*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Custom Minimal Policy (preferred)

For strict least privilege, grant only the two actions this skill needs:

```json
{
  "Version": "1.0",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "obs:bucket:ListAllMyBuckets",
        "obs:bucket:ListBucket",
        "obs:object:List"
      ],
      "Resource": [
        "obs:::bucket:*",
        "obs:::object:*"
      ]
    }
  ]
}
```

| Action | Needed for | Scope |
|--------|-----------|-------|
| `obs:bucket:ListAllMyBuckets` | `hcloud OBS ls` (list all buckets of the tenant) | All buckets |
| `obs:bucket:ListBucket` | `hcloud OBS ls obs://<bucket>` (list objects/folders in a bucket) | Target bucket |
| `obs:object:List` | List object keys (folder markers) inside a bucket | Target bucket |

## Notes

- **No write permissions** are required — do not grant `obs:bucket:CreateBucket`,
  `obs:object:PutObject`, `obs:object:DeleteObject`, etc.
- If the user only needs to inspect specific buckets, scope the `Resource`
  to those buckets instead of `*`.
- SDK access uses the same IAM permissions as the CLI.
