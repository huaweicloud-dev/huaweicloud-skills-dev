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

### Option C: Install via npm (alternative)

```bash
npm install -g @huaweicloud/hcloud
```

### Verify Installation

```bash
hcloud version
```

## Configure Authentication (AK/SK)

KooCLI needs an AK/SK profile before it can call Huawei Cloud APIs:

```bash
hcloud configure set --cli-profile=default --cli-access-key={AccessKeyId} --cli-secret-key={SecretAccessKey} --cli-region=cn-north-4 --cli-project-id={ProjectId}
```

Or run the interactive wizard:

```bash
hcloud configure
```

Verify authentication:

```bash
hcloud configure list
```

## Prefer Environment Variables

The skill reads credentials from the environment when present. The recommended
variables (in priority order) are:

| Priority | Variable | Description |
|----------|----------|-------------|
| 1 | `HUAWEI_ACCESS_KEY` / `HUAWEI_SECRET_KEY` | Primary AK/SK pair |
| 2 | `HWC_AK` / `HWC_SK` | Alternative AK/SK pair |

Never ask a user to paste their AK/SK into a conversation; have them set the
environment variables in their own terminal, or configure them into the KooCLI
profile.

## Notes

- This skill is read-only and uses `VPC ListVpcs` (v3/v2). No write permissions are needed.
- To see all supported regions for the VPC service: `hcloud VPC ListVpcs/v3 --cli-region=cn-north-4 --help`.
