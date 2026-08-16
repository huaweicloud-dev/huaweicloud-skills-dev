# Verification Method — huawei-cloud-network-query

This skill is **read-only**. Verification focuses on result correctness and environment readiness.

## 1. Environment Check

```bash
# Linux / macOS
skill action=exec: bash skill://scripts/check_env.sh

# Windows
skill action=exec: powershell -ExecutionPolicy Bypass -File skill://scripts/check_env.ps1
```

The check validates: Python version → dependencies → SDK importability → credentials (IAM call) → service availability.

## 2. Script Usage Check

Every script must be inspected with `-h` before execution:

```bash
skill action=exec: skill://.venv/bin/python3 skill://scripts/vpc/list_vpcs.py -h
```

`--project_id` must appear as optional (`[--project_id PROJECT_ID]`).

## 3. Functional Verification

| Step | Action | Expected |
|------|--------|----------|
| 1 | `scripts/vpc/list_vpcs.py --region cn-north-4` (no `--project_id`) | Returns VPC list; project ID auto-resolved via IAM |
| 2 | `scripts/vpc/list_vpcs.py --region cn-north-4 --project_id {explicit}` | Same result; explicit ID wins |
| 3 | `scripts/elb/list_api_versions.py --region cn-north-4` | Returns version list **without** credentials (public endpoint) |
| 4 | `scripts/dns/list_api_versions.py --region cn-north-4` | Returns version list; falls back to SDK when the region requires auth |
| 5 | Cross-check a known resource ID with the console | Fields (id/name/status) match the console |

## 4. Output Sanity

- Query results must come from real API responses — never inferred.
- When the result set is large, narrow scope with filters (`--name`, `--id`, `--marker` for pagination).
- No credential values may ever be printed.

## 5. Error Handling Verification

| Scenario | Expected behavior |
|----------|-------------------|
| No `--project_id`, no `HW_PROJECT_ID` | Script auto-resolves via IAM; on failure prints a clear message and suggests `--project_id` / `HW_PROJECT_ID` |
| No AK/SK | `load_credentials` reports missing env vars; version scripts work anonymously or explain auth is required |
| Resource not found | Script prints a friendly "no results" message with region context, exit 0 |
| Network/API error | Script prints `查询失败: <reason>` and exits non-zero |
