# Verification Method

This skill provides two independent ways to count OBS files: the KooCLI obsutil-backed command (primary) and the `huaweicloudsdkobs` Python SDK (fallback).

## Verification Script

Run the bundled test script from the skill directory:

```bash
bash scripts/test-cli-commands.sh <skill-path>
```

The script requires a real OBS bucket name via the `TEST_OBS_BUCKET` environment variable (defaults to `obs-hd-dev-static` if unset).

## Manual Verification Steps

1. **Prerequisite check** — confirm hcloud and obsutil are available:

   ```bash
   hcloud version
   hcloud OBS ls -s -limit=1
   ```

   If the second command returns `Please set ak, sk and endpoint in the configuration file!`, obsutil credentials are not configured.

2. **Whole-bucket file count (CLI primary)**:

   ```bash
   python3 scripts/count_obs_files.py --bucket <bucket_name>
   ```

   Expected: a single integer. Cross-check with:

   ```bash
   hcloud OBS ls obs://<bucket_name>/ -limit=0
   ```

   The `File number: N` line must equal the script output.

3. **Count under a prefix**:

   ```bash
   python3 scripts/count_obs_files.py --bucket <bucket_name> --prefix <prefix>
   ```

   Both `prefix` and `prefix/` forms are accepted and must return the same count.

4. **SDK fallback** — verify the SDK path returns the same count:

   ```bash
   python3 scripts/count_obs_files.py --bucket <bucket_name> --prefix <prefix> --executor sdk
   ```

5. **Empty prefix** — a prefix with no objects returns `0`:

   ```bash
   python3 scripts/count_obs_files.py --bucket <bucket_name> --prefix <nonexistent_prefix>
   ```

6. **Nonexistent bucket** — the script exits non-zero and prints a clear Chinese hint on stderr
   (`错误：指定的 OBS 桶不存在，或当前 AK/SK 无权访问该桶（NoSuchBucket）`):

   ```bash
   python3 scripts/count_obs_files.py --bucket <nonexistent_bucket>
   ```

   Expected: exit code 1, stderr contains the Chinese NoSuchBucket hint, stdout stays empty. The same
   behavior must hold with `--executor sdk`.

7. **Missing credentials (SDK path)** — run without AK/SK env vars:

   ```bash
   env -u HUAWEI_ACCESS_KEY -u HUAWEI_SECRET_KEY \
     python3 scripts/count_obs_files.py --bucket <bucket_name> --executor sdk
   ```

   Expected: exit code 1, stderr contains the Chinese credential hint with configuration guidance.

## Pass Criteria

- The CLI and SDK paths return the same file count for the same bucket/prefix
- The output is a single integer with no surrounding text
- Folder-marker keys (ending with `/`) are excluded — only real files count
- No create/update/delete operation is ever performed
- Error paths (nonexistent bucket, invalid/missing credentials) exit non-zero with a clear Chinese hint on stderr
