# Acceptance Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| 1 | Skill directory exists under `skills/network/nat/huawei-cloud-nat-list/` | `ls skills/network/nat/huawei-cloud-nat-list/` |
| 2 | `SKILL.md` exists with YAML frontmatter (`name`, `description`, `tags`, no `version`) | `bash scripts/validate-skill.sh skills/network/nat/huawei-cloud-nat-list` |
| 3 | `name` in frontmatter matches the directory name | validate-skill.sh check |
| 4 | `description` contains a feature summary and trigger words | validate-skill.sh check |
| 5 | Required sections present: Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents | validate-skill.sh check |
| 6 | `references/iam-policies.md` exists with least-privilege `nat:publicNatGateways:list` | validate-skill.sh check |
| 7 | `references/cli-installation-guide.md` exists | validate-skill.sh check |
| 8 | `references/verification-method.md` and `references/acceptance-criteria.md` exist | file existence |
| 9 | CLI command list works with real credentials | `bash scripts/test-cli-commands.sh skills/network/nat/huawei-cloud-nat-list cli` → all PASS |
| 10 | Name-only extraction returns gateway names | `hcloud NAT ListNatGateways --cli-region=cn-north-4 --cli-query="nat_gateways[].name"` |
| 11 | SDK fallback works | `bash scripts/test-cli-commands.sh skills/network/nat/huawei-cloud-nat-list sdk` → PASS |
| 12 | Quality wrapper reports (or disables cleanly) | `SKILL_QUALITY_DISABLE=1 python3 scripts/list_nat_gateways.py --region=cn-north-4 --names-only` |
| 13 | No credential hardcoding anywhere in the skill | Search the skill files (md/json/sh/py) for hardcoded access-key, secret-key, AK/SK or password patterns → no matches |
| 14 | Skill size ≤ 40 MB, file count ≤ 30, SKILL.md ≤ 500 lines | validate-skill.sh size checks |
| 15 | Read-only: no create/update/delete commands in the skill | review of Core Commands |
