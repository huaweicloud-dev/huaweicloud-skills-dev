# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/storage/dcs/huawei-cloud-dcs-list
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### CLI Mode

```bash
bash scripts/test-cli-commands.sh skills/storage/dcs/huawei-cloud-dcs-list cli
```

Test parameters are read from `templates/test-vars.json` (region, instance_id). Environment variables
`DCS_REGION`, `DCS_INSTANCE_ID` override them. Placeholder values such as `{instance_id}` in the JSON
are treated as unset.

The JSON also documents all test cases used by `test-cli-commands.sh`.

### SDK Mode (Fallback)

```bash
bash scripts/test-cli-commands.sh skills/storage/dcs/huawei-cloud-dcs-list sdk
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | List all DCS instances | `hcloud DCS ListInstances --cli-region=cn-north-4 --limit=100` |
| 2 | Extract DCS instance names | `hcloud DCS ListInstances --cli-region=cn-north-4 --limit=100 \| jq -r '.instances[].name'` |
| 3 | Filter instances by name | `hcloud DCS ListInstances --cli-region=cn-north-4 --name={name}` |
| 4 | Filter instances by status | `hcloud DCS ListInstances --cli-region=cn-north-4 --status=RUNNING` |
| 5 | Show instance detail | `hcloud DCS ShowInstance --cli-region=cn-north-4 --instance_id=<instance_id>` |

## Expected Results

- All query commands return HTTP 200 with valid JSON
- Empty results are valid (no instances matching the filter in the project)
- `ShowInstance` requires an existing `instance_id`
- The instance list response contains an `instances` array; each item's `name` is the instance name, `status` is the instance status, and `instance_id` is the instance ID
