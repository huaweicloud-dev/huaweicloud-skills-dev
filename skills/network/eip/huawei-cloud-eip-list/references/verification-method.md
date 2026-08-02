# Verification Method

This skill provides two independent ways to list EIPs: the KooCLI command (primary) and the `huaweicloudsdkeip` Python SDK (fallback).

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

2. **Full listing** — verify EIP IDs, public IP addresses, and count:

   ```bash
   hcloud EIP ListPublicips --cli-region=cn-north-4
   ```

3. **JSON listing** — verify structured output:

   ```bash
   hcloud EIP ListPublicips --cli-region=cn-north-4 --cli-output=json
   ```

4. **IP version filter** — verify filtering:

   ```bash
   hcloud EIP ListPublicips --cli-region=cn-north-4 --ip_version.1=4
   ```

5. **EIP detail** — verify the show-detail path with a known EIP ID:

   ```bash
   hcloud EIP ShowPublicip/v3 --cli-region=cn-north-4 --publicip_id=<eip-id>
   ```

6. **SDK fallback** — verify the SDK path returns the same EIP set:

   ```bash
   python3 - <<'EOF'
   import os
   from huaweicloudsdkcore.auth.credentials import BasicCredentials
   from huaweicloudsdkeip.v2 import EipClient
   from huaweicloudsdkeip.v2.model import ListPublicipsRequest
   from huaweicloudsdkeip.v2.region.eip_region import EipRegion
   creds = BasicCredentials(os.environ["HUAWEI_CLOUD_ACCESS_KEY"], os.environ["HUAWEI_CLOUD_SECRET_KEY"])
   client = EipClient.new_builder().with_credentials(creds).with_region(EipRegion.value_of("cn-north-4")).build()
   resp = client.list_publicips(ListPublicipsRequest())
   eips = resp.publicips or []
   print("EIP number:", len(eips))
   EOF
   ```

## Pass Criteria

- At least one of the CLI or SDK paths succeeds with the authenticated account
- The returned EIP count is consistent between CLI and SDK (when both are run)
- No create/update/delete operation is ever performed
