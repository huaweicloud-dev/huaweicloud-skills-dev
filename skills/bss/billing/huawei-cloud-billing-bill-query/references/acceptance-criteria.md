# Acceptance Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| 1 | Skill directory exists under `skills/bss/billing/huawei-cloud-billing-bill-query/` | `ls skills/bss/billing/huawei-cloud-billing-bill-query/` |
| 2 | `SKILL.md` exists with YAML frontmatter (`name`, `description`, `tags`, no `version`) | `bash scripts/validate-skill.sh skills/bss/billing/huawei-cloud-billing-bill-query` |
| 3 | `name` in frontmatter matches the directory name | validate-skill.sh check |
| 4 | `description` contains a feature summary and trigger words | validate-skill.sh check |
| 5 | Required sections present: Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents | validate-skill.sh check |
| 6 | `references/iam-policies.md` exists with least-privilege `bss:bill:view` | validate-skill.sh check |
| 7 | `references/cli-installation-guide.md` exists (SDK setup, since KooCLI does not support BSS) | validate-skill.sh check |
| 8 | `references/verification-method.md` and `references/acceptance-criteria.md` exist | file existence |
| 9 | Quality SDK vendored and integrated | `scripts/skill_quality_sdk.py` exists and `scripts/query_bills.py` uses `quality_context` |
| 10 | All three actions work with real credentials | `bash scripts/test-cli-commands.sh skills/bss/billing/huawei-cloud-billing-bill-query sdk` → PASS |
| 11 | JSON output is valid | `python3 scripts/query_bills.py --action fee-records --format json` parses with `jq`/`json.loads` |
| 12 | No credential hardcoding anywhere in the skill | Search the skill files (md/json/sh/py) for hardcoded access-key, secret-key, AK/SK or password patterns → no matches |
| 13 | Skill size ≤ 40 MB, file count ≤ 30, SKILL.md ≤ 500 lines | validate-skill.sh size checks |
| 14 | Read-only: no create/update/delete operations in the skill | review of Core Commands |
| 15 | Time scope limited to one billing cycle (one month) | review of `query_bills.py` — all actions take a single `YYYY-MM` cycle; no multi-month queries |
