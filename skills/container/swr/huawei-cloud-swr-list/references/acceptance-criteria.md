# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | ListReposDetails returns valid response | `hcloud SWR ListReposDetails --cli-region={region} --limit=10` succeeds and returns a repository array (or empty array) |
| 2 | Repository attributes are present in the response | Each item's `name`, `namespace`, `is_public`, `num_images`, and `path` are returned in the array |
| 3 | Namespace filter works | `hcloud SWR ListReposDetails --cli-region={region} --namespace=group-dev` succeeds |
| 4 | Name fuzzy filter works | `hcloud SWR ListReposDetails --cli-region={region} --name=nginx` succeeds |
| 5 | Category filter works | `hcloud SWR ListReposDetails --cli-region={region} --category=database` succeeds |
| 6 | Pagination works | `--limit` and `--offset` are accepted and page through results |
| 7 | Sorting works | `--order_column` and `--order_type` are accepted and sort results |
| 8 | SDK fallback works | `huaweicloudsdkswr.v2` `list_repos_details` returns the same data |

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
