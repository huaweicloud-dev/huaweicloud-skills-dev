# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/storage/sfsturbo/huawei-cloud-sfsturbo-list
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### CLI Mode

```bash
bash scripts/test-cli-commands.sh skills/storage/sfsturbo/huawei-cloud-sfsturbo-list cli
```

Test parameters are read from `templates/test-vars.json` (region). The
environment variable `SFSTURBO_REGION` overrides the region.

### SDK Mode (Fallback)

```bash
bash scripts/test-cli-commands.sh skills/storage/sfsturbo/huawei-cloud-sfsturbo-list sdk
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | List all file systems | `hcloud SFSTurbo ListShares --cli-region=cn-north-4` |
| 2 | SFS name list | `hcloud SFSTurbo ListShares --cli-region=cn-north-4` piped to `jq -r '.shares[].name'` |
| 3 | Pagination | `hcloud SFSTurbo ListShares --cli-region=cn-north-4 --limit=10 --offset=0` |
| 4 | SDK fallback | `python3` script calling `SfsturboClient.list_shares` |
| 5 | Wrapper script | `SKILL_QUALITY_DISABLE=1 python3 scripts/list_sfsturbo_shares.py --names-only` prints SFS names |

## Expected Results

- All query commands return HTTP 200 with valid JSON
- Empty results are valid (no SFS file system in the project/region)
- `ListShares` returns a `shares` array; each item's `name` is the file system
  name, `id` is the file system id, `status` is the file system status
  (e.g. `100` = available), `size` is the capacity in GB, `share_proto` is the
  protocol (`NFS` / `SMB`), and `region` is the region
