# CLI Installation Guide

## Install hcloud CLI

Download and install the Huawei Cloud KooCLI:

```bash
# Linux amd64
curl -sL https://cn-north-4-hdn-koocli.obs.cn-north-4.myhuaweicloud.com/cli/latest/huaweicloud-cli-linux-amd64.tar.gz -o hcloud.tar.gz
tar -xzf hcloud.tar.gz
chmod +x hcloud
sudo mv hcloud /usr/local/bin/

# Linux arm64
curl -sL https://cn-north-4-hdn-koocli.obs.cn-north-4.myhuaweicloud.com/cli/latest/huaweicloud-cli-linux-arm64.tar.gz -o hcloud.tar.gz
tar -xzf hcloud.tar.gz
chmod +x hcloud
sudo mv hcloud /usr/local/bin/

# macOS amd64
curl -sL https://cn-north-4-hdn-koocli.obs.cn-north-4.myhuaweicloud.com/cli/latest/huaweicloud-cli-mac-amd64.tar.gz -o hcloud.tar.gz
tar -xzf hcloud.tar.gz
chmod +x hcloud
sudo mv hcloud /usr/local/bin/

# macOS arm64
curl -sL https://cn-north-4-hdn-koocli.obs.cn-north-4.myhuaweicloud.com/cli/latest/huaweicloud-cli-mac-arm64.tar.gz -o hcloud.tar.gz
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
hcloud SWR ListReposDetails --cli-region=cn-north-4 --limit=10
```

## SDK Fallback

If the CLI is unavailable, install the Python SDK:

```bash
pip install huaweicloudsdkswr huaweicloudsdkcore
```
