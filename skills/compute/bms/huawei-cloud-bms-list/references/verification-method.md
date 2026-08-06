# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/compute/bms/huawei-cloud-bms-list
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### CLI Mode

```bash
bash scripts/test-cli-commands.sh skills/compute/bms/huawei-cloud-bms-list cli
```

Test parameters are read from `templates/test-vars.json` (region). The environment
variable `BMS_REGION` overrides the region.

### SDK Mode (Fallback)

```bash
bash scripts/test-cli-commands.sh skills/compute/bms/huawei-cloud-bms-list sdk
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | List all servers | `hcloud BMS ListBareMetalServers --cli-region=cn-north-4` |
| 2 | Server name list | `hcloud BMS ListBareMetalServers --cli-region=cn-north-4` piped to `jq -r '.servers[].name'` |
| 3 | Filter by status | `hcloud BMS ListBareMetalServers --cli-region=cn-north-4 --status=ACTIVE` |
| 4 | Filter by name | `hcloud BMS ListBareMetalServers --cli-region=cn-north-4 --name=bms-01` |
| 5 | SDK fallback | `python3` script calling `BmsClient.list_bare_metal_servers` |

## Expected Results

- All query commands return HTTP 200 with valid JSON
- Empty results are valid (no BMS in the project)
- The list response contains a `servers` array; each item's top-level `name`
  field is the server name, `id` is the server id and `status` is the server status
