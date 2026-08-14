# CLI Installation Guide

## Install hcloud CLI

Download and install the Huawei Cloud KooCLI:

```bash
# Linux amd64
curl -sL https://hwcloudcli.obs.cn-north-4.myhuaweicloud.com/cli/latest/hcloud_cli_linux_amd64.tar.gz -o hcloud.tar.gz
tar -xzf hcloud.tar.gz
chmod +x hcloud
sudo mv hcloud /usr/local/bin/

# macOS
curl -sL https://hwcloudcli.obs.cn-north-4.myhuaweicloud.com/cli/latest/hcloud_cli_mac_amd64.tar.gz -o hcloud.tar.gz
tar -xzf hcloud.tar.gz
chmod +x hcloud
sudo mv hcloud /usr/local/bin/
```

## Authenticate

```bash
# Interactive configuration (region + AK/SK)
hcloud configure set --cli-region=cn-north-4
hcloud configure set --cli-profile=default --cli-mode=AKSK --cli-access-key=<your-ak> --cli-secret-key=<your-sk>
```

> Do **not** hardcode credentials into any file. Prefer environment variables:

```bash
export HUAWEICLOUD_SDK_AK="<your-ak>"
export HUAWEICLOUD_SDK_SK="<your-sk>"
```

## Verify Installation

```bash
hcloud version
hcloud BMS ListBareMetalServers --cli-region=cn-north-4 --cli-output=json
```

## SDK Fallback

If the CLI is unavailable, install the Python SDK:

```bash
pip install huaweicloudsdkbms huaweicloudsdkcore
```
