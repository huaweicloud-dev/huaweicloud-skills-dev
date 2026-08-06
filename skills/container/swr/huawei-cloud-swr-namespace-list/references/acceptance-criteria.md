# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | ListNamespaces returns valid response | `hcloud SWR ListNamespaces --cli-region={region}` succeeds and returns a namespace list (or empty array) |
| 2 | Namespace attributes are present in the response | Each item's `id`, `name`, `creator_name`, `auth`, and `repo_count` are returned in the `namespaces` array |
| 3 | Namespace name filter works | `hcloud SWR ListNamespaces --cli-region={region} --namespace=group-dev` succeeds |
| 4 | SDK fallback works | `huaweicloudsdkswr.v2` `list_namespaces` returns the same data via `response.body` |

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
