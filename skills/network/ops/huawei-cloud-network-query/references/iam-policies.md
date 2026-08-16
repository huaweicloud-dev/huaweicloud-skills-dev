# IAM Policies — huawei-cloud-network-query

This skill performs **read-only** queries against Huawei Cloud network services via the
Huawei Cloud Python SDK. Follow the principle of least privilege: grant only the
`*:list*` / `*:get*` (read) actions shown below. No write actions (`create`/`update`/`delete`)
are needed.

## Recommended Custom Policy

```json
{
  "Version": "1.0",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "vpc:list*",
        "vpc:get*",
        "vpc:show*",
        "eip:list*",
        "eip:get*",
        "eip:show*",
        "elb:list*",
        "elb:get*",
        "elb:show*",
        "nat:list*",
        "nat:get*",
        "nat:show*",
        "dns:list*",
        "dns:get*",
        "dns:show*",
        "vpn:list*",
        "vpn:get*",
        "vpn:show*",
        "iam:projects:listProjects"
      ],
      "Resource": ["*"]
    }
  ]
}
```

> `iam:projects:listProjects` is required only for the automatic project-ID resolution
> (when `--project_id` is omitted, the script calls IAM `KeystoneListProjects` to look up
> the project ID for the target region). If `HW_PROJECT_ID` is always set or `--project_id`
> is always passed, this action can be dropped.

## Predefined Policy Alternatives

If custom policies are not available in your environment, the following system-defined
read-only roles cover the same actions (choose per service actually used):

| Service | Predefined Role |
|---------|-----------------|
| VPC | `VPC ReadOnlyAccess` |
| EIP | `EIP ReadOnlyAccess` |
| ELB | `ELB ReadOnlyAccess` |
| NAT | `NAT ReadOnlyAccess` |
| DNS | `DNS ReadOnlyAccess` |
| VPN | `VPN ReadOnlyAccess` |

> Note: using multiple predefined roles may exceed the single-role quota of a user;
> prefer the single custom policy above.

## Credentials

- AK/SK are read from environment variables (`HW_ACCESS_KEY` / `HW_SECRET_KEY`), never
  hardcoded in scripts or documents.
- When using temporary credentials, also set `HW_SECURITY_TOKEN`.
- `HW_PROJECT_ID` (optional): when set, scripts skip the IAM project lookup.
- `HW_REGION_NAME` (optional): default region, defaults to `cn-north-4`.

## Permission Verification

```bash
python3 scripts/check_env.sh        # validates credentials via IAM
python3 scripts/vpc/list_vpcs.py --region cn-north-4   # smoke test
```
