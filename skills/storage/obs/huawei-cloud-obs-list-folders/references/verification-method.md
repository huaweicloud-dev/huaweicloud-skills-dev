# Verification Method

## Functional Verification

### 1. CLI path (primary)

```bash
# List all buckets
hcloud OBS ls

# List folders at the root of a bucket
hcloud OBS ls obs://<bucket>

# List sub-folders under a prefix
hcloud OBS ls obs://<bucket>/<prefix> -d
```

Expected: `hcloud OBS ls` prints `obs://<bucket>` lines; bucket listings
contain a `Folder list:` section with the folder names.

### 2. Wrapper script (recommended)

```bash
python3 scripts/list_obs_folders.py --buckets-only
python3 scripts/list_obs_folders.py --bucket <bucket> --folders-only
python3 scripts/list_obs_folders.py --bucket <bucket> --prefix <prefix> --folders-only
```

Expected: bucket names / folder names printed one per line.

### 3. SDK fallback

```bash
python3 scripts/list_obs_folders.py --bucket <bucket> --folders-only --executor sdk
```

Expected: same folder names as the CLI path (when the env AK/SK has the
required permissions), or a clear Chinese error message (NoSuchBucket /
AccessDenied / InvalidAccessKeyId / 未配置凭证).

### 4. Error paths

| Scenario | Command | Expected |
|----------|---------|----------|
| Nonexistent bucket | `python3 scripts/list_obs_folders.py --bucket no-such-bucket-xyz --folders-only` | exit 1, stderr contains the NoSuchBucket hint |
| Missing hcloud CLI | run without `hcloud` installed | exit 1, stderr: 「未找到 hcloud (KooCLI) 命令」 |
| Missing AK/SK | env vars unset, SDK executor | exit 1, stderr: 「未找到 AK/SK 凭证」 |

## Cross-Check CLI vs SDK

```bash
python3 scripts/list_obs_folders.py --bucket <bucket> --folders-only            # CLI
python3 scripts/list_obs_folders.py --bucket <bucket> --folders-only --executor sdk  # SDK
```

When both credentials have permission, the two outputs should be consistent
(folder names ending with `/`). Differences can arise only when the env
AK/SK differs from the obsutil credentials.

## Quality Reporting

Each wrapper-script run reports a `trace_id`, status
(`success` / `biz_fail` / `sys_fail`), error code and cost to the skillsopr
operations console via the vendored `scripts/skill_quality_sdk.py`. To
disable reporting for local debugging:

```bash
export SKILL_QUALITY_DISABLE=1
```
