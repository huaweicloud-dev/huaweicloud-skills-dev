# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | ListBareMetalServers returns valid response | `hcloud BMS ListBareMetalServers --cli-region={region}` succeeds and returns the server list |
| 2 | Server names are present in the response | Each item's `name` field is returned |
| 3 | Server name-only extraction works | `hcloud BMS ListBareMetalServers --cli-region={region}` piped to `jq -r '.servers[].name'` prints one name per line |
| 4 | Status filter works | `hcloud BMS ListBareMetalServers --cli-region={region} --status=ACTIVE` succeeds |
| 5 | Name filter works | `hcloud BMS ListBareMetalServers --cli-region={region} --name=bms-01` succeeds |
| 6 | Pagination works | `hcloud BMS ListBareMetalServers --cli-region={region} --limit=25 --offset=1` succeeds |
| 7 | SDK fallback works | `BmsClient.list_bare_metal_servers` returns the same server list |

## Non-Functional Criteria

| # | Criterion | Threshold |
|---|-----------|-----------|
| 1 | All commands are read-only | No create/update/delete operations |
| 2 | CLI command response time | < 10s for list operations |
| 3 | SDK fallback works when CLI unavailable | Query methods available via SDK |
| 4 | No credential hardcoding | AK/SK from environment variables only |
| 5 | IAM least privilege | `bms:servers:list` only |

## Compliance Criteria

| # | Criterion | Check |
|---|-----------|-------|
| 1 | SKILL.md frontmatter valid | name + description + tags present |
| 2 | All required sections present | Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents |
| 3 | No version field in frontmatter | `version` key absent |
| 4 | File count <= 30 | Count all files in skill directory |
| 5 | SKILL.md line count <= 500 | Line count check |
