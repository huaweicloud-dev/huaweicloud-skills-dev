# Acceptance Criteria — huawei-cloud-vpc-list

| # | Criterion | Status |
|---|-----------|--------|
| 1 | `SKILL.md` exists with YAML frontmatter (`name`, `description`, `tags`) | ✅ |
| 2 | Frontmatter `name` matches the directory name `huawei-cloud-vpc-list` | ✅ |
| 3 | `description` includes a feature summary and trigger words (list VPC / 查询VPC列表) | ✅ |
| 4 | No `version` field in frontmatter | ✅ |
| 5 | `Overview`, `Prerequisites`, `Workflow`, `Core Commands`, `Parameter Confirmation`, `Reference Documents` sections present | ✅ |
| 6 | `references/iam-policies.md` exists with least-privilege read-only policy | ✅ |
| 7 | `references/cli-installation-guide.md` exists (CLI is used) | ✅ |
| 8 | All concrete commands use `hcloud VPC ListVpcs` with valid PascalCase operation and `--cli-region` | ✅ |
| 9 | Commands verified live: v3 and v2 both return real VPC data | ✅ |
| 10 | Read-only skill — no create/update/delete commands | ✅ |
| 11 | Total content size ≤ 40 MB, file count ≤ 30, SKILL.md ≤ 500 lines | ✅ |
| 12 | Every file uses an allowed extension | ✅ |
| 13 | No hardcoded credentials in any file | ✅ |
| 14 | PR diff changes only the `huawei-cloud-vpc-list` skill directory | ✅ |
| 15 | Accurate VPC count: paginates with `--marker` until `next_marker` is absent, never reports `current_count` alone | ✅ |
| 16 | All six creation phases complete | ✅ |
