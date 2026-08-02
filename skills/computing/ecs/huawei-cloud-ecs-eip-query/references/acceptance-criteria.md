# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-01 | Skill returns the EIP(s) bound to a given ECS ID | `hcloud EIP ListPublicips/v3 --vnic.device_id.1=<ecs-id>` returns the bound EIPs |
| AC-02 | Detailed output includes EIP metadata | Output shows EIP ID, public IP address, status, bandwidth, and binding details |
| AC-03 | ECS name resolution works | `hcloud ECS ListServersDetails --name=<name>` returns the ECS ID used for the EIP query |
| AC-04 | ECS detail confirms the binding | `hcloud ECS ShowServer --server_id=<id>` shows a floating address matching the EIP public IP |
| AC-05 | EIP detail query works | `hcloud EIP ShowPublicip/v3 --publicip_id=<id>` returns the full EIP detail |
| AC-06 | SDK fallback works | `huaweicloudsdkeip` `list_publicips` with `vnic_device_id` returns the same EIP set |
| AC-07 | No-EIP case is handled | An ECS without a bound EIP returns an empty result with a clear message |
| AC-08 | Read-only guarantee | No create/update/delete operation is invoked by this skill |

## Security Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-S1 | No AK/SK hardcoded in skill files | grep for `AK=`, `SK=`, `access.key=`, `secret.key=` on the skill directory returns nothing |
| AC-S2 | No KooCLI `configure set` credential command | SKILL.md and references never include KooCLI `configure set` with credential flags |
| AC-S3 | Least-privilege policies | `references/eip-policies.md` grants only `vpc:publicIps:list`/`get` and `ecs:servers:list`/`get` |
| AC-S4 | No cross-skill calls | SKILL.md does not reference other skill names |

## Quality Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-Q1 | SKILL.md follows the Huawei Cloud Skill Specification | `bash scripts/validate-skill.sh <skill-path>` passes with zero Critical failures |
| AC-Q2 | Markdown passes markdownlint | `markdownlint-cli2 "**/*.md" --config .markdownlint.json` reports no ERROR |
| AC-Q3 | Test script passes | `bash scripts/test-cli-commands.sh <skill-path> --executor cli` reports PASS for TC-01 |
| AC-Q4 | SKILL.md <= 500 lines, total files <= 30 | `wc -l SKILL.md` reports line count; `find . -type f` reports file count |
