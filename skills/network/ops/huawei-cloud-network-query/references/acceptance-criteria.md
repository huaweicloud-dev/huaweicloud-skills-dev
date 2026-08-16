# Acceptance Criteria — huawei-cloud-network-query

## Functional Criteria

1. **Query coverage**: VPC / EIP / ELB / NAT / DNS / VPN resources can be listed and detailed via the scripts in `scripts/<service>/guide.md`-documented script names only.
2. **Read-only guarantee**: the skill performs no create/update/delete operations; no script mutates resources.
3. **Project ID optional** (ISSUE-001 fix): every query script accepts `--project_id` as optional.
   - When omitted and `HW_PROJECT_ID` is set → that value is used.
   - When omitted and `HW_PROJECT_ID` is unset → the script auto-resolves the project ID via the IAM `KeystoneListProjects` API for the target region.
   - Failure to auto-resolve produces a clear message suggesting `--project_id` or `HW_PROJECT_ID`.
4. **Public version queries** (ISSUE-002 fix): `scripts/elb/list_api_versions.py` and `scripts/dns/list_api_versions.py` no longer require credentials at the top level and no longer require `--project_id`.
   - ELB version list is retrievable anonymously.
   - DNS version list works anonymously where the region allows; otherwise it falls back to the SDK with credentials and explains the requirement.
5. **No fabricated data**: all output comes from real Huawei Cloud API responses.

## Environment Criteria

6. `HW_ACCESS_KEY` / `HW_SECRET_KEY` required for authenticated queries; `HW_SECURITY_TOKEN` when using temporary credentials; `HW_REGION_NAME` optional (default `cn-north-4`); `HW_PROJECT_ID` optional.
7. Credentials are never hardcoded or echoed in output.
8. `check_env.sh` / `check_env.ps1` complete all 5 validation steps before queries run.

## Compliance Criteria

9. `validate-skill.sh` passes all Critical and High checks (the >30 file count is a known accepted design trade-off: one script per API).
10. Execution-quality reporting via `scripts/skill_quality_sdk.py` is non-blocking and fails silently; `SKILL_QUALITY_DISABLE=1` disables it.

## Regression Acceptance

11. All scripts pass `python3 -m py_compile`.
12. `-h` works on every script (with credentials configured).
13. The two ISSUE defects are verified by the test cases in `references/verification-method.md` section 3.
