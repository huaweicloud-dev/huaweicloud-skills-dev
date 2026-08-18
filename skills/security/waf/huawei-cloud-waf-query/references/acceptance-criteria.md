# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
| --- | ----------- | -------------- |
| AC-1 | Skill can list attack events in a time window | `hcloud WAF ListEvent --from=... --to=... --pagesize=5` returns valid JSON with `total` and `items` |
| AC-2 | Skill can show attack event detail | `hcloud WAF ShowEvent --eventid=<id>` returns event detail JSON |
| AC-3 | Skill can page through access/protection logs | `hcloud WAF ListEventLog --page=1 --pagesize=5` returns log entries |
| AC-4 | Skill can show attack statistics overview | `hcloud WAF ListStatistics --from=... --to=...` returns per-category counts |
| AC-5 | Skill can show threat overview for a recent period | `hcloud WAF ListThreats --recent=today` returns threat summary |
| AC-6 | Skill can list top attack source IPs | `hcloud WAF ListTopIp --from=... --to=...` returns ranked IP list |
| AC-7 | All commands include `--cli-region` and `--project_id` | Inspect each command |
| AC-8 | Read-only: no Create/Update/Delete operations | Skill only uses List/Show operations |

## Quality Criteria

| # | Criterion |
| --- | ----------- |
| AC-9 | SKILL.md contains Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents |
| AC-10 | No hardcoded credentials anywhere |
| AC-11 | references/iam-policies.md provides least-privilege read-only policy |
| AC-12 | All API paths in phase-2-summary.json come from verified CLI help output, not inferred |
| AC-13 | SKILL.md ≤ 500 lines; total files ≤ 30; size ≤ 40 MB |
