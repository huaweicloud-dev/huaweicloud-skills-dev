# IAM Policies

## Required Permissions

The AK/SK used by this skill requires the following OBS permissions:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "obs:bucket:ListAllMyBuckets",
        "obs:object:ListObject"
      ],
      "Resource": [
        "OBS:*:*:bucket:*",
        "OBS:*:*:object:*/*"
      ]
    }
  ]
}
```

## Least Privilege Notes

- `obs:bucket:ListAllMyBuckets` — Required to enumerate all buckets in the account
- `obs:object:ListObject` — Required to list objects within each bucket
- No write permissions (`PutObject`, `DeleteObject`) are granted — this skill is read-only
- No bucket modification permissions (`PutBucketAcl`, `DeleteBucket`) are granted

## Policy Attachment

Attach this policy to the IAM user or agency associated with your AK/SK via the Huawei Cloud IAM console.