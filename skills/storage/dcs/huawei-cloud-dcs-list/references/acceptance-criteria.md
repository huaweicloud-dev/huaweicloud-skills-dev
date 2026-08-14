# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | ListInstances returns valid response | `hcloud DCS ListInstances --cli-region={region}` succeeds and returns instance list |
| 2 | Instance names are present in the response | Each item's `name` field is returned in the `instances` array |
| 3 | Name filter works | `hcloud DCS ListInstances --cli-region={region} --name={name}` returns matching instances |
| 4 | Status filter works | `hcloud DCS ListInstances --cli-region={region} --status=RUNNING` succeeds |
| 5 | ShowInstance returns details | Requires existing instance_id |

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
