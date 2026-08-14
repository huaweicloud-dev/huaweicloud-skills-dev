# Verification Method

## Verify the skill works

### 1. CLI-only smoke test

```bash
hcloud RDS ListInstances --cli-region=cn-north-4 --limit=5 --cli-output=json
```

Expected: JSON object with an `instances` array. Each element has at least
`id`, `name`, `status`, `datastore`, `flavor_ref`.

### 2. Name-only output (the primary use case)

```bash
python3 scripts/list_rds_instances.py --region=cn-north-4 --names-only
```

Expected: one RDS instance name per line. Example:

```
rds-vod-prod
```

### 3. Wrapper fallback to SDK

```bash
python3 scripts/list_rds_instances.py --region=cn-north-4 --names-only --executor sdk
```

Expected: identical name list. If the SDK package is missing, the error
message explains the missing dependency.

### 4. Filters

```bash
python3 scripts/list_rds_instances.py --region=cn-north-4 --datastore_type=MySQL --names-only
python3 scripts/list_rds_instances.py --region=cn-north-4 --type=Ha --compact
```

### 5. Automated functional test

```bash
bash scripts/test-cli-commands.sh {skill-path} --executor cli
bash scripts/test-cli-commands.sh {skill-path} --executor sdk
```

## Error handling

| Symptom | Meaning | Action |
|---------|---------|--------|
| `[USE_ERROR]` | CLI usage/parameter error | Check parameter names/values |
| `error_msg` in output | API rejected the call | Check AK/SK + IAM policy (`rds:instance:list`) |
| `ERROR: ... (U04)` | Permission/API failure | Grant `RDS ReadOnlyAccess` |
| `(no RDS instances found ...)` | Query matched nothing | Relax filters (name/type/region) |
| `ERROR: ... (C01)` | Missing credentials | Export AK/SK environment variables |

## Quality reporting

Every run of `scripts/list_rds_instances.py` reports to the skillsopr
operations console via `scripts/skill_quality_sdk.py` (trace_id, status,
error code, cost). Set `SKILL_QUALITY_DISABLE=1` to disable reporting for
local debugging.
