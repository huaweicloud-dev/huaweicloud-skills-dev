# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | ListClustersDetails returns valid response | `hcloud CSS ListClustersDetails --cli-region={region} --limit=10` succeeds and returns a cluster list (or empty array) |
| 2 | Cluster attributes are present in the response | Each item's `id`, `name`, `status`, and `endpoint` are returned in the `clusters` array |
| 3 | Engine-type filter works | `hcloud CSS ListClustersDetails --cli-region={region} --datastoreType=elasticsearch` succeeds |
| 4 | Pagination works | `--limit` and `--offset` are accepted and page through results |
| 5 | SDK fallback works | `huaweicloudsdkcss.v1` `list_clusters_details` returns the same data |

## Non-Functional Criteria

| # | Criterion | Threshold |
|---|-----------|-----------|
| 1 | All commands are read-only | No create/update/delete operations |
| 2 | CLI command response time | < 10s for list operations |
| 3 | SDK fallback works when CLI unavailable | Query methods available via SDK |
| 4 | No credential hardcoding | AK/SK from environment variables only |
| 5 | IAM least privilege | ReadOnlyAccess only |

## Compliance Criteria

| # | Criterion | Check |
|---|-----------|-------|
| 1 | SKILL.md frontmatter valid | name + description + tags present |
| 2 | All required sections present | Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents |
| 3 | No version field in frontmatter | `version` key absent |
| 4 | File count <= 30 | Count all files in skill directory |
| 5 | SKILL.md line count <= 500 | Line count check |
