# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-01 | Skill lists all IAM roles owned by the account | `hcloud IAM KeystoneListPermissions --cli-region=cn-north-4` returns IAM roles with a total count |
| AC-02 | Detailed output includes role metadata | Output shows role ID, display name, internal name, catalog, and type |
| AC-03 | Filter by permission type works | `hcloud IAM KeystoneListPermissions --permission_type=role` returns only system-defined roles |
| AC-04 | Filter by domain ID works | `hcloud IAM KeystoneListPermissions --domain_id=<id>` returns only custom policies of the account |
| AC-05 | Filter by service catalog works | `hcloud IAM KeystoneListPermissions --catalog=CCE` returns roles of that catalog |
| AC-06 | SDK fallback works | `huaweicloudsdkiam` `keystone_list_permissions` returns the same role set |
| AC-07 | Read-only guarantee | No create/update/delete operation is invoked by this skill |

## Security Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-S1 | No AK/SK hardcoded in skill files | grep for `AK=`, `SK=`, `access.key=`, `secret.key=` on the skill directory returns nothing |
| AC-S2 | No KooCLI `configure set` credential command | SKILL.md and references never include KooCLI `configure set` with credential flags |
| AC-S3 | Least-privilege IAM policy | `references/iam-policies.md` grants only `iam:roles:listRoles` |
| AC-S4 | No cross-skill calls | SKILL.md does not reference other skill names |

## Quality Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-Q1 | SKILL.md follows the Huawei Cloud Skill Specification | `bash scripts/validate-skill.sh <skill-path>` passes with zero Critical failures |
| AC-Q2 | Markdown passes markdownlint | `markdownlint-cli2 "**/*.md" --config .markdownlint.json` reports no ERROR |
| AC-Q3 | Test script passes | `bash scripts/test-cli-commands.sh <skill-path> --executor cli` reports PASS for TC-01 |
| AC-Q4 | SKILL.md <= 500 lines, total files <= 30 | `wc -l SKILL.md` reports line count; `find . -type f` reports file count |
