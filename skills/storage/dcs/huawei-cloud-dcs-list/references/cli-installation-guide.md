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
# Interactive login
hcloud configure set --cli-region=cn-north-4
hcloud configure set --access-key=*** --secret-key=***

# Or use environment variables
export HUAWEI_ACCESS_KEY="your-ak"
export HUAWEI_SECRET_KEY="your-sk"
```

## Verify Installation

```bash
hcloud version
hcloud DCS ListInstances --cli-region=cn-north-4 --limit=10
```

## SDK Fallback

If the CLI is unavailable, install the Python SDK:

```bash
pip install huaweicloudsdkdcs huaweicloudsdkcore
```
