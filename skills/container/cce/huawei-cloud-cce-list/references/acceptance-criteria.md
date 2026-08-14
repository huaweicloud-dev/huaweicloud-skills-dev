# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | ListClusters returns valid response | `hcloud CCE ListClusters --cli-region={region}` succeeds and returns the cluster list |
| 2 | Cluster names are present in the response | Each item's `metadata.name` is returned |
| 3 | Cluster name-only extraction works | `hcloud CCE ListClusters --cli-region={region}` piped to `jq -r '.items[].metadata.name'` prints one name per line |
| 4 | Status filter works | `hcloud CCE ListClusters --cli-region={region} --status=Available` succeeds |
| 5 | Type filter works | `hcloud CCE ListClusters --cli-region={region} --type=VirtualMachine` succeeds |
| 6 | SDK fallback works | `CceClient.list_clusters` returns the same cluster list |

## Non-Functional Criteria

| # | Criterion | Threshold |
|---|-----------|-----------|
| 1 | All commands are read-only | No create/update/delete operations |
| 2 | CLI command response time | < 10s for list operations |
| 3 | SDK fallback works when CLI unavailable | Query methods available via SDK |
| 4 | No credential hardcoding | AK/SK from environment variables only |
| 5 | IAM least privilege | `cce:cluster:list` only |

## Compliance Criteria

| # | Criterion | Check |
|---|-----------|-------|
| 1 | SKILL.md frontmatter valid | name + description + tags present |
| 2 | All required sections present | Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents |
| 3 | No version field in frontmatter | `version` key absent |
| 4 | File count <= 30 | Count all files in skill directory |
| 5 | SKILL.md line count <= 500 | Line count check |
