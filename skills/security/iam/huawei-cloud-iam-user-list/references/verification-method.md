# Verification Method

This skill provides two independent ways to list IAM users: the KooCLI command (primary) and the `huaweicloudsdkiam` Python SDK (fallback).

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

2. **Full listing** — verify user IDs, names, enabled status, and count:

   ```bash
   hcloud IAM KeystoneListUsers --cli-region=cn-north-4
   ```

3. **JSON listing** — verify structured output:

   ```bash
   hcloud IAM KeystoneListUsers --cli-region=cn-north-4 --cli-output=json
   ```

4. **Name filter** — verify filtering:

   ```bash
   hcloud IAM KeystoneListUsers --cli-region=cn-north-4 --name=<user-name>
   ```

5. **SDK fallback** — verify the SDK path returns the same user set:

   ```bash
   python3 - <<'EOF'
   import os
   from huaweicloudsdkcore.auth.credentials import BasicCredentials
   from huaweicloudsdkiam.v3 import IamClient
   from huaweicloudsdkiam.v3.model import KeystoneListUsersRequest
   from huaweicloudsdkiam.v3.region.iam_region import IamRegion
   creds = BasicCredentials(os.environ["HUAWEI_CLOUD_ACCESS_KEY"], os.environ["HUAWEI_CLOUD_SECRET_KEY"])
   client = IamClient.new_builder().with_credentials(creds).with_region(IamRegion.value_of("cn-north-4")).build()
   resp = client.keystone_list_users(KeystoneListUsersRequest())
   users = resp.users or []
   print("User number:", len(users))
   EOF
   ```

## Pass Criteria

- At least one of the CLI or SDK paths succeeds with the authenticated account
- The returned user count is consistent between CLI and SDK (when both are run)
- No create/update/delete operation is ever performed
