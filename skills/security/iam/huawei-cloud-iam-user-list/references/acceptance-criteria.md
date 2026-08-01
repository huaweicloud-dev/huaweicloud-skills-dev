# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-01 | Skill lists all IAM users owned by the account | `hcloud IAM KeystoneListUsers --cli-region=cn-north-4` returns IAM users with a total count |
| AC-02 | Detailed output includes user metadata | Output shows user ID, name, enabled status, and description |
| AC-03 | Filter by user name works | `hcloud IAM KeystoneListUsers --name=<name>` returns only matching users |
| AC-04 | Filter by domain ID works | `hcloud IAM KeystoneListUsers --domain_id=<id>` returns users of that domain |
| AC-05 | SDK fallback works | `huaweicloudsdkiam` `keystone_list_users` returns the same user set |
| AC-06 | Read-only guarantee | No create/update/delete operation is invoked by this skill |

## Security Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-S1 | No AK/SK hardcoded in skill files | grep for `AK=`, `SK=`, `access.key=`, `secret.key=` on the skill directory returns nothing |
| AC-S2 | No KooCLI `configure set` credential command | SKILL.md and references never include KooCLI `configure set` with credential flags |
| AC-S3 | Least-privilege IAM policy | `references/iam-policies.md` grants only `iam:users:listUsers` |
| AC-S4 | No cross-skill calls | SKILL.md does not reference other skill names |

## Quality Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-Q1 | SKILL.md follows the Huawei Cloud Skill Specification | `bash scripts/validate-skill.sh <skill-path>` passes with zero Critical failures |
| AC-Q2 | Markdown passes markdownlint | `markdownlint-cli2 "**/*.md" --config .markdownlint.json` reports no ERROR |
| AC-Q3 | Test script passes | `bash scripts/test-cli-commands.sh <skill-path> --executor cli` reports PASS for TC-01 |
| AC-Q4 | SKILL.md <= 500 lines, total files <= 30 | `wc -l SKILL.md` reports line count; `find . -type f` reports file count |
