# Acceptance Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| 1 | Skill directory exists under `skills/database/rds/huawei-cloud-rds-list/` | `ls skills/database/rds/huawei-cloud-rds-list/` |
| 2 | `SKILL.md` has valid frontmatter (name, description, tags, no version) | `head -20 SKILL.md` |
| 3 | Frontmatter `name` matches the directory name | `grep '^name:' SKILL.md` |
| 4 | `description` contains feature summary + trigger words | `grep 'Triggers include:' SKILL.md` |
| 5 | Required sections present: Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents | `grep -E '^## (Overview\|Prerequisites\|Workflow\|Core Commands\|Parameter Confirmation\|Reference Documents)' SKILL.md` |
| 6 | `references/iam-policies.md` exists | file check |
| 7 | `references/cli-installation-guide.md` exists | file check |
| 8 | Mandatory quality SDK vendored and integrated | `ls scripts/skill_quality_sdk.py` and `grep quality_context scripts/list_rds_instances.py` |
| 9 | No hardcoded credentials | `grep -RniE 'AK[=]\|SK[=]\|access[.]key[=]\|secret[.]key[=]' scripts/ references/` |
| 10 | CLI query returns the `instances` array | `hcloud RDS ListInstances --cli-region=cn-north-4 --limit=5 --cli-output=json` |
| 11 | Name-only output prints one RDS instance name per line | `python3 scripts/list_rds_instances.py --region=cn-north-4 --names-only` |
| 12 | SDK fallback returns the same list | `python3 scripts/list_rds_instances.py --region=cn-north-4 --names-only --executor sdk` |
| 13 | Filters (datastore_type / type / name) narrow results correctly | run filtered queries and eyeball output |
| 14 | Skill is strictly read-only (no create/delete/restart commands) | grep SKILL.md and scripts for mutating operations |
| 15 | Functional test script passes | `bash scripts/test-cli-commands.sh {path} --executor cli` and `--executor sdk` |
| 16 | `validate-skill.sh` passes with 0 critical failures | `bash scripts/validate-skill.sh {path}` |

## Sign-off

- [ ] All acceptance criteria above pass
- [ ] Live CLI query verified against a real region
- [ ] SDK fallback verified
- [ ] PR contains only the single skill directory
