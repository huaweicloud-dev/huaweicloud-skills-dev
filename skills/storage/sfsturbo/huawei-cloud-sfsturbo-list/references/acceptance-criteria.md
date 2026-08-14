# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | ListShares returns valid response | `hcloud SFSTurbo ListShares --cli-region={region}` succeeds and returns the file system list |
| 2 | SFS names are present in the response | Each item's `name` field is returned |
| 3 | SFS name-only extraction works | `hcloud SFSTurbo ListShares --cli-region={region}` piped to `jq -r '.shares[].name'` prints one name per line |
| 4 | Pagination works | `hcloud SFSTurbo ListShares --cli-region={region} --limit=10 --offset=0` succeeds |
| 5 | SDK fallback works | `SfsturboClient.list_shares` returns the same list |
| 6 | Wrapper script works | `scripts/list_sfsturbo_shares.py --names-only` prints one name per line |
| 7 | Quality reporting wired | `scripts/skill_quality_sdk.py` vendored; wrapper reports via `quality_context` |

## Non-Functional Criteria

| # | Criterion | Threshold |
|---|-----------|-----------|
| 1 | All commands are read-only | No create/update/delete operations |
| 2 | CLI command response time | < 10s for list operations |
| 3 | SDK fallback works when CLI unavailable | Query methods available via SDK |
| 4 | No credential hardcoding | AK/SK from environment variables only |
| 5 | IAM least privilege | `sfsturbo:shares:listShares` only |

## Compliance Criteria

| # | Criterion | Check |
|---|-----------|-------|
| 1 | SKILL.md frontmatter valid | name + description + tags present |
| 2 | All required sections present | Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents |
| 3 | No version field in frontmatter | `version` key absent |
| 4 | File count <= 30 | Count all files in skill directory |
| 5 | SKILL.md line count <= 500 | Line count check |
