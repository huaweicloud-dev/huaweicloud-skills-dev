# IAM Policies

## Least-Privilege Policy for NAT List

This skill only queries the public NAT gateway list (NAT service, v2 API
`GET /v2/{project_id}/nat_gateways`). The following IAM policy grants
read-only NAT gateway listing with least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "nat:publicNatGateways:list"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, the system policy `NAT ReadOnlyAccess` also works — it
includes all NAT read permissions (public NAT gateways, SNAT rules, DNAT
rules). It is broader than the least-privilege policy above, so prefer the
fine-grained `nat:publicNatGateways:list` policy when possible.

## Notes

- This skill performs **no write operations** — all commands are read-only
- No `nat:publicNatGateways:create`, `nat:publicNatGateways:update`,
  `nat:publicNatGateways:delete`, or SNAT/DNAT rule permissions are needed
- The project ID is resolved automatically by the CLI from the authenticated profile
