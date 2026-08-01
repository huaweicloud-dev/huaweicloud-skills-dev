# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-01 | Skill lists all security groups of the project | `hcloud VPC ListSecurityGroups --cli-region=cn-north-4` returns security groups with a total count |
| AC-02 | Detailed output includes security group metadata | Output shows security group ID, name, description, enterprise project ID, and tags |
| AC-03 | Filter by security group name works | `hcloud VPC ListSecurityGroups --name.1=<name>` returns only matching groups |
| AC-04 | Filter by security group ID works | `hcloud VPC ListSecurityGroups --id.1=<id>` returns only the group with that ID |
| AC-05 | Enterprise project filter works | `hcloud VPC ListSecurityGroups --enterprise_project_id=0` returns groups of the default project |
| AC-06 | SDK fallback works | `huaweicloudsdkvpc` `list_security_groups` returns the same security group set |
| AC-07 | Read-only guarantee | No create/update/delete operation is invoked by this skill |

## Security Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-S1 | No AK/SK hardcoded in skill files | grep for `AK=`, `SK=`, `access.key=`, `secret.key=` on the skill directory returns nothing |
| AC-S2 | No KooCLI `configure set` credential command | SKILL.md and references never include KooCLI `configure set` with credential flags |
| AC-S3 | Least-privilege VPC policy | `references/vpc-policies.md` grants only `vpc:securityGroups:list` |
| AC-S4 | No cross-skill calls | SKILL.md does not reference other skill names |

## Quality Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-Q1 | SKILL.md follows the Huawei Cloud Skill Specification | `bash scripts/validate-skill.sh <skill-path>` passes with zero Critical failures |
| AC-Q2 | Markdown passes markdownlint | `markdownlint-cli2 "**/*.md" --config .markdownlint.json` reports no ERROR |
| AC-Q3 | Test script passes | `bash scripts/test-cli-commands.sh <skill-path> --executor cli` reports PASS for TC-01 |
| AC-Q4 | SKILL.md <= 500 lines, total files <= 30 | `wc -l SKILL.md` reports line count; `find . -type f` reports file count |
