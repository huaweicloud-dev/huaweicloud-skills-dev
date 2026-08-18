# KooCLI Installation and Authentication Guide

## Install KooCLI (hcloud)

### Option 1: Package manager

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y hcloud-cli

# CentOS/RHEL
sudo yum install -y hcloud-cli
```

### Option 2: Direct binary

```bash
curl -sSL https://cn-north-4-hcli.obs.cn-north-4.myhuaweicloud.com/cli/latest/hcloud_install.sh -o hcloud_install.sh
bash hcloud_install.sh
```

### Option 3: pip

```bash
pip install huaweicloud-cli
```

## Configure Authentication (AK/SK)

```bash
hcloud configure set --cli-profile=default \
  --cli-mode=AKSK \
  --cli-region=cn-north-4 \
  --cli-access-key=<YOUR_ACCESS_KEY> \
  --cli-secret-key=<YOUR_SECRET_KEY>
```

> **Security note:** Never hardcode AK/SK in scripts or documents. Use environment variables instead:

```bash
export HUAWEICLOUD_SDK_AK=<YOUR_ACCESS_KEY>
export HUAWEICLOUD_SDK_SK=<YOUR_SECRET_KEY>
```

## Verify Installation

```bash
hcloud --version
hcloud WAF --cli-region=cn-north-4 --help
```

## Obtain Project ID

```bash
hcloud IAM KeystoneListProjects --cli-region=cn-north-4 --name=cn-north-4
```

Or from the console: username → **My Credentials** → **Projects**.
