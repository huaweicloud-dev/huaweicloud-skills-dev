# CLI Installation Guide — huawei-cloud-vpc-list

## Install KooCLI (hcloud)

The `hcloud` CLI (KooCLI) is required to run the primary commands of this skill.

### Option A: Install via download + extract (Linux)

```bash
curl -O https://obs-community-tool.obs.cn-north-1.myhuaweicloud.com/hcloudcli/latest/hcloudcli-linux-amd64.tar.gz
tar -xzf hcloudcli-linux-amd64.tar.gz
chmod +x hcloud
sudo mv hcloud /usr/local/bin/
```

### Option B: Install via Python pip

```bash
pip3 install huaweicloudcli
```

## Configure Authentication (AK/SK)

Run the interactive configuration wizard:

```bash
hcloud configure init
```

Or set the profile non-interactively:

```bash
hcloud configure set --cli-profile=default --cli-mode=AKSK \
  --cli-access-key=YOUR_ACCESS_KEY --cli-secret-key=YOUR_SECRET_KEY \
  --cli-region=cn-north-4 --cli-project-id=YOUR_PROJECT_ID
```

> **Security:** Never hardcode credentials in scripts or documentation. Read AK/SK from
> environment variables (`HUAWEICLOUD_SDK_AK`, `HUAWEICLOUD_SDK_SK`) or a local secure
> profile. The commands above should be run by the user in their own shell.

## Verify Installation

```bash
hcloud version
hcloud configure list
```

## Region and Project

- The CLI uses the region and project bound to the configured profile.
- Override per-command with `--cli-region={region}`.
- The VPC API is region-scoped; the `project_id` in the API path is derived from the
  configured profile automatically.
