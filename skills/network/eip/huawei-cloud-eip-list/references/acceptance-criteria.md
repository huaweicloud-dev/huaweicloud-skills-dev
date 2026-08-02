# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-01 | Skill lists all EIPs of the project | `hcloud EIP ListPublicips --cli-region=cn-north-4` returns EIPs with a total count |
| AC-02 | Detailed output includes EIP metadata | Output shows EIP ID, public IP address, status, bandwidth, and associated instance |
| AC-03 | Filter by EIP ID works | `hcloud EIP ListPublicips --id.1=<id>` returns only the EIP with that ID |
| AC-04 | Filter by IP version works | `hcloud EIP ListPublicips --ip_version.1=4` returns only IPv4 EIPs |
| AC-05 | Enterprise project filter works | `hcloud EIP ListPublicips --enterprise_project_id.1=0` returns EIPs of the default project |
| AC-06 | EIP detail query works | `hcloud EIP ShowPublicip/v3 --publicip_id=<id>` returns the full EIP detail |
| AC-07 | SDK fallback works | `huaweicloudsdkeip` `list_publicips` returns the same EIP set |
| AC-08 | Read-only guarantee | No create/update/delete operation is invoked by this skill |

## Security Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-S1 | No AK/SK hardcoded in skill files | grep for `AK=`, `SK=`, `access.key=`, `secret.key=` on the skill directory returns nothing |
| AC-S2 | No KooCLI `configure set` credential command | SKILL.md and references never include KooCLI `configure set` with credential flags |
| AC-S3 | Least-privilege EIP policy | `references/eip-policies.md` grants only `vpc:publicIps:list` and `vpc:publicIps:get` |
| AC-S4 | No cross-skill calls | SKILL.md does not reference other skill names |

## Quality Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-Q1 | SKILL.md follows the Huawei Cloud Skill Specification | `bash scripts/validate-skill.sh <skill-path>` passes with zero Critical failures |
| AC-Q2 | Markdown passes markdownlint | `markdownlint-cli2 "**/*.md" --config .markdownlint.json` reports no ERROR |
| AC-Q3 | Test script passes | `bash scripts/test-cli-commands.sh <skill-path> --executor cli` reports PASS for TC-01 |
| AC-Q4 | SKILL.md <= 500 lines, total files <= 30 | `wc -l SKILL.md` reports line count; `find . -type f` reports file count |
