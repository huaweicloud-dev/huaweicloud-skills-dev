# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/storage/evs/huawei-cloud-evs-list
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### CLI Mode

```bash
bash scripts/test-cli-commands.sh skills/storage/evs/huawei-cloud-evs-list cli
```

Test parameters are read from `templates/test-vars.json` (region). The
environment variable `EVS_REGION` overrides the region.

### SDK Mode (Fallback)

```bash
bash scripts/test-cli-commands.sh skills/storage/evs/huawei-cloud-evs-list sdk
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | List all disks | `hcloud EVS ListVolumes --cli-region=cn-north-4` |
| 2 | Disk name list | `hcloud EVS ListVolumes --cli-region=cn-north-4` piped to `jq -r '.volumes[].name'` |
| 3 | Filter by status | `hcloud EVS ListVolumes --cli-region=cn-north-4 --status=available` |
| 4 | Filter by name | `hcloud EVS ListVolumes --cli-region=cn-north-4 --name=data-disk-01` |
| 5 | SDK fallback | `python3` script calling `EvsClient.list_volumes` |

## Expected Results

- All query commands return HTTP 200 with valid JSON
- Empty results are valid (no EVS disk in the project)
- The list response contains a `volumes` array; each item's top-level `name`
  field is the disk name, `id` is the disk id, `status` is the disk status and
  `size` is the disk size in GB
