# IAM Policies

## Least-Privilege Policy for VPCEP List

This skill only queries the VPCEP (VPC Endpoint / VPC Endpoint Service) list.
The following IAM policy grants read-only listing with least privilege:

```json
{
  "Version": "1.1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "vpcep:endpoints:list",
        "vpcep:endpointServices:list"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Alternative: System Policy

For convenience, the system policy `VPCEndpoint ReadOnlyAccess` also works — it
includes all VPCEP read permissions (endpoints, endpoint services, connections,
quotas). It is broader than the least-privilege policy above, so prefer the
fine-grained actions when possible.

## Notes

- This skill performs **no write operations** — all commands are read-only
- No `vpcep:endpoints:create`, `vpcep:endpoints:delete`,
  `vpcep:endpointServices:create`, `vpcep:endpointServices:delete`, or
  connection-approval permissions are needed
- The project ID is resolved automatically by the CLI from the authenticated profile
