# CLI Installation Guide (hcloud / KooCLI + OBS)

The skill uses the **KooCLI** (`hcloud`) command line tool. The OBS service of
KooCLI is **obsutil-backed** — `hcloud OBS <command>` maps to obsutil
commands such as `ls`, `stat`, `config`.

## 1. Install KooCLI (hcloud)

Reference: https://support.huaweicloud.com/qs-hcli/hcli_02_003.html

```bash
# Linux / macOS
curl -sSL https://hwcloudcli.obs.cn-north-4.myhuaweicloud.com/cli/latest/hcloud_install.sh -o hcloud_install.sh
bash hcloud_install.sh

# Verify
hcloud version
```

## 2. Configure Authentication

### Option A — configure obsutil credentials via hcloud (recommended)

```bash
hcloud OBS config -i=<YourAK> -k=<YourSK> -e=obs.<Region>.myhuaweicloud.com
# Example (cn-north-4):
hcloud OBS config -i=<YourAK> -k=<YourSK> -e=obs.cn-north-4.myhuaweicloud.com
```

This writes `~/.obsutilconfig`, which obsutil (and therefore
`hcloud OBS ls`) reads for credentials.

### Option B — environment variables (used by the SDK fallback)

The SDK fallback reads AK/SK from environment variables:

```bash
export HUAWEI_ACCESS_KEY=<YourAK>
export HUAWEI_SECRET_KEY=<YourSK>
# or
export HUAWEICLOUD_SDK_AK=<YourAK>
export HUAWEICLOUD_SDK_SK=<YourSK>
```

> **Security note:** never paste AK/SK into chat or commit them to files.
> Obtain AK/SK from the Huawei Cloud console: 「我的凭证 / My Credentials」.

## 3. Verify the OBS connection

```bash
hcloud OBS ls
```

If credentials are configured correctly, the command prints the bucket list
(`obs://<bucket-name>` lines). If it fails, re-check the AK/SK and the
endpoint region.

## 4. (Optional) Python SDK fallback

```bash
pip install huaweicloudsdkobs
```

The fallback executor in `scripts/list_obs_folders.py` uses
`huaweicloudsdkobs.v1.ObsClient` (`list_buckets` / `list_objects`). It is
only used when the CLI path fails and the `--executor auto` mode falls back,
or when `--executor sdk` is explicitly requested.
