# Verification Method

This skill provides two independent ways to list security groups: the KooCLI command (primary) and the `huaweicloudsdkvpc` Python SDK (fallback).

## Verification Script

Run the bundled test script from the skill directory:

```bash
bash scripts/test-cli-commands.sh <skill-path> --executor cli
```

For the SDK fallback:

```bash
bash scripts/test-cli-commands.sh <skill-path> --executor sdk
```

## Manual Verification Steps

1. **Prerequisite check** — confirm hcloud is available and configured:

   ```bash
   hcloud version
   ```

   If hcloud is not configured, run `hcloud configure` with AK/SK (see `references/cli-installation-guide.md`).

2. **Full listing** — verify security group IDs, names, and count:

   ```bash
   hcloud VPC ListSecurityGroups --cli-region=cn-north-4
   ```

3. **JSON listing** — verify structured output:

   ```bash
   hcloud VPC ListSecurityGroups --cli-region=cn-north-4 --cli-output=json
   ```

4. **Name filter** — verify filtering:

   ```bash
   hcloud VPC ListSecurityGroups --cli-region=cn-north-4 --name.1=<sg-name>
   ```

5. **SDK fallback** — verify the SDK path returns the same security group set:

   ```bash
   python3 - <<'EOF'
   import os
   from huaweicloudsdkcore.auth.credentials import BasicCredentials
   from huaweicloudsdkvpc.v3 import VpcClient
   from huaweicloudsdkvpc.v3.model import ListSecurityGroupsRequest
   from huaweicloudsdkvpc.v3.region.vpc_region import VpcRegion
   creds = BasicCredentials(os.environ["HUAWEI_CLOUD_ACCESS_KEY"], os.environ["HUAWEI_CLOUD_SECRET_KEY"])
   client = VpcClient.new_builder().with_credentials(creds).with_region(VpcRegion.value_of("cn-north-4")).build()
   resp = client.list_security_groups(ListSecurityGroupsRequest())
   groups = resp.security_groups or []
   print("Security group number:", len(groups))
   EOF
   ```

## Pass Criteria

- At least one of the CLI or SDK paths succeeds with the authenticated account
- The returned security group count is consistent between CLI and SDK (when both are run)
- No create/update/delete operation is ever performed
