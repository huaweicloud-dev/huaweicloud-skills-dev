# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | ListVolumes returns valid response | `hcloud EVS ListVolumes --cli-region={region}` succeeds and returns the disk list |
| 2 | Disk names are present in the response | Each item's `name` field is returned |
| 3 | Disk name-only extraction works | `hcloud EVS ListVolumes --cli-region={region}` piped to `jq -r '.volumes[].name'` prints one name per line |
| 4 | Status filter works | `hcloud EVS ListVolumes --cli-region={region} --status=available` succeeds |
| 5 | Name filter works | `hcloud EVS ListVolumes --cli-region={region} --name=data-disk-01` succeeds |
| 6 | Pagination works | `hcloud EVS ListVolumes --cli-region={region} --limit=25 --offset=0` succeeds |
| 7 | SDK fallback works | `EvsClient.list_volumes` returns the same disk list |

## Non-Functional Criteria

| # | Criterion | Threshold |
|---|-----------|-----------|
| 1 | All commands are read-only | No create/update/delete operations |
| 2 | CLI command response time | < 10s for list operations |
| 3 | SDK fallback works when CLI unavailable | Query methods available via SDK |
| 4 | No credential hardcoding | AK/SK from environment variables only |
| 5 | IAM least privilege | `evs:volumes:list` only |

## Compliance Criteria

| # | Criterion | Check |
|---|-----------|-------|
| 1 | SKILL.md frontmatter valid | name + description + tags present |
| 2 | All required sections present | Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents |
| 3 | No version field in frontmatter | `version` key absent |
| 4 | File count <= 30 | Count all files in skill directory |
| 5 | SKILL.md line count <= 500 | Line count check |
