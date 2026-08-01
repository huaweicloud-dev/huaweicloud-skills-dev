# CLI Installation Guide

This skill requires **hcloud (KooCLI)** for the primary execution path.

## Table of Contents

- [Install hcloud](#install-hcloud)
- [Configure Credentials](#configure-credentials)
- [Verify Installation](#verify-installation)
- [Troubleshooting](#troubleshooting)

---

## Install hcloud

### Linux (x86_64)

```bash
curl -O https://cn-north-4-hdn-koocli.obs.cn-north-4.myhuaweicloud.com/cli/latest/huaweicloud-cli-linux-amd64.tar.gz
tar -xzf huaweicloud-cli-linux-amd64.tar.gz
chmod +x hcloud
sudo mv hcloud /usr/local/bin/
```

### Linux (ARM64)

```bash
curl -O https://cn-north-4-hdn-koocli.obs.cn-north-4.myhuaweicloud.com/cli/latest/huaweicloud-cli-linux-arm64.tar.gz
tar -xzf huaweicloud-cli-linux-arm64.tar.gz
chmod +x hcloud
sudo mv hcloud /usr/local/bin/
```

### macOS (Intel / Apple Silicon)

```bash
# Intel (x86_64)
curl -O https://cn-north-4-hdn-koocli.obs.cn-north-4.myhuaweicloud.com/cli/latest/huaweicloud-cli-mac-amd64.tar.gz
tar -xzf huaweicloud-cli-mac-amd64.tar.gz
chmod +x hcloud
sudo mv hcloud /usr/local/bin/

# Apple Silicon (arm64)
curl -O https://cn-north-4-hdn-koocli.obs.cn-north-4.myhuaweicloud.com/cli/latest/huaweicloud-cli-mac-arm64.tar.gz
tar -xzf huaweicloud-cli-mac-arm64.tar.gz
chmod +x hcloud
sudo mv hcloud /usr/local/bin/
```

> Note: `brew install hcloudcli` is **not** an official KooCLI formula (Homebrew's `hcloud` is the Hetzner Cloud CLI,
> unrelated to Huawei Cloud). Always install from the official download package or npm path below.

### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "https://cn-north-4-hdn-koocli.obs.cn-north-4.myhuaweicloud.com/cli/latest/huaweicloud-cli-windows-amd64.zip" -OutFile "huaweicloud-cli-windows-amd64.zip"
Expand-Archive huaweicloud-cli-windows-amd64.zip
# Add hcloud.exe to PATH
```

### Node.js / npm (alternative)

```bash
npm install -g @huaweicloud/hcloud
```

---

## Configure Credentials

**Never ask the user to paste AK/SK directly into the conversation.** Instruct them to run the following in their own terminal:

```bash
hcloud configure
```

Follow the interactive prompts to enter the Access Key ID (AK), Secret Access Key (SK), and region. AK/SK can be obtained from the Huawei Cloud console "My Credentials" page.

Alternative: set environment variables `HUAWEI_CLOUD_ACCESS_KEY` and `HUAWEI_CLOUD_SECRET_KEY`.

---

## Verify Installation

```bash
hcloud version
hcloud IAM KeystoneListUsers --cli-region=cn-north-4 --cli-output=json
```

A successful run prints the IAM user list in JSON format.

---

## Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| `command not found: hcloud` | hcloud not in PATH — install or add to PATH |
| `InvalidAccessKeyId` or auth error | Wrong AK/SK or expired key — rerun `hcloud configure` |
| `User has no permission` | IAM policy missing `iam:users:listUsers` — see `references/iam-policies.md` |
| `Missing required parameter --cli-region` | Add `--cli-region=<region>` to the command |
