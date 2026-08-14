# Acceptance Criteria

Use this checklist to verify the skill is ready for production use.

## Functional

- [ ] `python3 scripts/list_obs_folders.py --buckets-only` lists the OBS
      buckets of the tenant, one name per line.
- [ ] `python3 scripts/list_obs_folders.py --bucket <bucket> --folders-only`
      lists the folder names at the root of the bucket (folder names end
      with `/`).
- [ ] `python3 scripts/list_obs_folders.py --bucket <bucket> --prefix <prefix> --folders-only`
      lists sub-folder names under the given prefix.
- [ ] The CLI path (`hcloud OBS ls`) works with configured obsutil
      credentials.
- [ ] The SDK fallback (`--executor sdk`) returns the same folder names
      when the env AK/SK has permissions; otherwise it returns a clear
      Chinese error (NoSuchBucket / AccessDenied / InvalidAccessKeyId /
      未配置凭证).
- [ ] A nonexistent bucket produces exit code 1 with the NoSuchBucket hint.
- [ ] Missing AK/SK produces a clear "未找到 AK/SK 凭证" error.

## Read-Only Guarantee

- [ ] The skill never creates, modifies or deletes buckets, folders or
      objects (no mutating OBS commands or SDK calls).
- [ ] All commands are `ls` / `list_*` operations only.

## Quality & Security

- [ ] `scripts/skill_quality_sdk.py` is vendored and every wrapper-script
      run reports trace_id / status / error code / cost (non-blocking).
- [ ] `SKILL_QUALITY_DISABLE=1` disables reporting for local debugging.
- [ ] No AK/SK hardcoded in any file; credentials come from obsutil config
      (CLI) or environment variables (SDK).
- [ ] IAM policies in `references/iam-policies.md` follow least privilege.

## Specification Compliance

- [ ] SKILL.md exists with YAML frontmatter (`name`, `description` with
      trigger words, ≤ 5 `tags`, no `version`).
- [ ] Required sections present: Overview, Prerequisites, Workflow,
      Core Commands, Parameter Confirmation, Reference Documents,
      KooCLI Command Format Standard.
- [ ] `references/iam-policies.md` and `references/cli-installation-guide.md`
      exist; other references are kebab-case.
- [ ] All file extensions are in the allowlist; SKILL.md ≤ 500 lines;
      total files ≤ 30; total size ≤ 40 MB.
- [ ] `bash scripts/validate-skill.sh <skill-path>` passes all Critical and
      High checks.
