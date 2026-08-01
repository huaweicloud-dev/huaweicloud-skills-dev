# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-01 | Skill lists all projects owned by the account | `hcloud IAM KeystoneListProjects --cli-region=cn-north-4` returns projects with a total count |
| AC-02 | Detailed output includes project metadata | Output shows project ID, name, domain ID, parent ID, and enabled status |
| AC-03 | Filter by project name works | `hcloud IAM KeystoneListProjects --name=<name>` returns only matching projects |
| AC-04 | Filter by domain ID works | `hcloud IAM KeystoneListProjects --domain_id=<id>` returns projects of that account |
| AC-05 | Filter by enabled status works | `hcloud IAM KeystoneListProjects --enabled=true` returns only enabled projects |
| AC-06 | Pagination works | `hcloud IAM KeystoneListProjects --page=1 --per_page=50` returns a paged result |
| AC-07 | SDK fallback works | `huaweicloudsdkiam` `keystone_list_projects` returns the same project set |
| AC-08 | Read-only guarantee | No create/update/delete operation is invoked by this skill |

## Security Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-S1 | No AK/SK hardcoded in skill files | grep for `AK=`, `SK=`, `access.key=`, `secret.key=` on the skill directory returns nothing |
| AC-S2 | No KooCLI `configure set` credential command | SKILL.md and references never include KooCLI `configure set` with credential flags |
| AC-S3 | Least-privilege IAM policy | `references/iam-policies.md` grants only `iam:projects:listProjects` |
| AC-S4 | No cross-skill calls | SKILL.md does not reference other skill names |

## Quality Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-Q1 | SKILL.md follows the Huawei Cloud Skill Specification | `bash scripts/validate-skill.sh <skill-path>` passes with zero Critical failures |
| AC-Q2 | Markdown passes markdownlint | `markdownlint-cli2 "**/*.md" --config .markdownlint.json` reports no ERROR |
| AC-Q3 | Test script passes | `bash scripts/test-cli-commands.sh <skill-path> --executor cli` reports PASS for TC-01 |
| AC-Q4 | SKILL.md <= 500 lines, total files <= 30 | `wc -l SKILL.md` reports line count; `find . -type f` reports file count |
