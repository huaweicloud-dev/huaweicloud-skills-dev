# Verification Method

This skill provides two independent ways to query the EIP of a single ECS: the KooCLI command (primary) and the `huaweicloudsdkeip` Python SDK (fallback).

## Verification Script

Run the bundled test script from the skill directory:

```bash
HUAWEI_CLOUD_ECS_ID=<ecs-id> HUAWEI_CLOUD_EIP_ID=<eip-id> bash scripts/test-cli-commands.sh <skill-path> --executor cli
```

> **Note:** TC-05 (`ShowPublicip/v3 detail`) performs a **functional** check against a real EIP and
> requires `HUAWEI_CLOUD_EIP_ID` to be set to the ID of an EIP bound to the target ECS (e.g. taken from
> the TC-01/TC-02 result). If the variable is unset, TC-05 is **skipped** (it is not a placeholder
> pass). TC-01/TC-02/TC-04 need `HUAWEI_CLOUD_ECS_ID`; TC-03 (`ListServersDetails by name`) uses a
> literal `--name=test` as a syntax smoke check.

For the SDK fallback:

```bash
HUAWEI_CLOUD_ECS_ID=<ecs-id> bash scripts/test-cli-commands.sh <skill-path> --executor sdk
```

## Manual Verification Steps

1. **Prerequisite check** — confirm hcloud is available and configured:

   ```bash
   hcloud version
   ```

   If hcloud is not configured, run `hcloud configure` with AK/SK (see `references/cli-installation-guide.md`).

2. **Query EIP by ECS ID** — the primary path:

   ```bash
   hcloud EIP ListPublicips/v3 --cli-region=cn-north-4 --vnic.device_id.1=<ecs-id>
   ```

3. **JSON output** — verify structured output:

   ```bash
   hcloud EIP ListPublicips/v3 --cli-region=cn-north-4 --vnic.device_id.1=<ecs-id> --cli-output=json
   ```

4. **Resolve ECS by name** — when only the ECS name is known:

   ```bash
   hcloud ECS ListServersDetails --cli-region=cn-north-4 --name=<ecs-name>
   ```

5. **ECS detail** — verify the ECS addresses (floating address = the bound EIP):

   ```bash
   hcloud ECS ShowServer --cli-region=cn-north-4 --server_id=<ecs-id>
   ```

6. **EIP detail** — verify the EIP metadata with a known EIP ID:

   ```bash
   hcloud EIP ShowPublicip/v3 --cli-region=cn-north-4 --publicip_id=<eip-id>
   ```

7. **SDK fallback** — verify the SDK path returns the same EIP set:

   ```bash
   python3 - <<'EOF'
   import os
   from huaweicloudsdkcore.auth.credentials import BasicCredentials
   from huaweicloudsdkeip.v3 import EipClient
   from huaweicloudsdkeip.v3.model import ListPublicipsRequest
   from huaweicloudsdkeip.v3.region.eip_region import EipRegion
   creds = BasicCredentials(os.environ["HUAWEI_CLOUD_ACCESS_KEY"], os.environ["HUAWEI_CLOUD_SECRET_KEY"])
   client = EipClient.new_builder().with_credentials(creds).with_region(EipRegion.value_of("cn-north-4")).build()
   req = ListPublicipsRequest()
   req.vnic_device_id = [os.environ["HUAWEI_CLOUD_ECS_ID"]]
   resp = client.list_publicips(req)
   eips = resp.publicips or []
   print("EIP number:", len(eips))
   EOF
   ```

## Pass Criteria

- At least one of the CLI or SDK paths succeeds with the authenticated account
- The returned EIP count matches the ECS's actual bound EIP count (visible in `hcloud ECS ShowServer` addresses)
- No create/update/delete operation is ever performed
