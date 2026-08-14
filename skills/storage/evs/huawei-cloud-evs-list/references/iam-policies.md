# IAM Policies

## Least-Privilege Policy for EVS List

This skill only queries the EVS (Elastic Volume Service) disk list. The
following IAM policy grants read-only disk listing with least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "evs:volumes:list"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, the system policy `EVS ReadOnlyAccess` also works — it
includes all EVS read permissions (disks, snapshots, volume types, quotas). It
is broader than the least-privilege policy above, so prefer the fine-grained
`evs:volumes:list` policy when possible.

## Notes

- This skill performs **no write operations** — all commands are read-only
- No `evs:volumes:create`, `evs:volumes:delete`, `evs:volumes:update`,
  `evs:snapshots:*`, or attach/detach permissions are needed
- The project ID is resolved automatically by the CLI from the authenticated profile
