# Acceptance Criteria

## Functional Criteria

- [x] **Count GaussDB for openGauss instances**: The skill returns the total number of GaussDB for openGauss instances in a region
- [x] **Count GaussDB (MySQL) instances**: The skill returns the total number of GaussDB (MySQL-compatible) instances in a region
- [x] **Total count**: The skill reports a combined total across both GaussDB families
- [x] **CLI mode**: `hcloud GaussDBforopenGauss ListInstances` and `hcloud GaussDB ListGaussMySqlInstances` work when the CLI is installed
- [x] **SDK fallback**: Python SDK `list_instances()` and `list_gauss_my_sql_instances()` work when the CLI is unavailable
- [x] **Accurate count**: The count is read from the authoritative `total_count` field, never truncated to one page
- [x] **Read-only**: No write operation is ever performed

## Non-Functional Criteria

- [x] No AK/SK hardcoding — credentials come from environment variables or hcloud profile
- [x] Least-privilege IAM policy documented
- [x] SKILL.md within 500 lines, file count within 30, total size within 40 MB
- [x] Reference documents use kebab-case filenames

## Out of Scope

- Creating / deleting / modifying GaussDB instances (write operations)
- Querying GaussDB instance details (CPU, memory, status) — use a separate detail skill
