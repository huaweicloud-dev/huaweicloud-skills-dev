# CLI Installation Guide

## hcloud CLI (KooCLI) Installation

### Linux/macOS One-Click Install

```bash
curl -sSL https://hwcloudcli.obs.cn-north-1.myhuaweicloud.com/cli/latest/hcloud_install.sh | bash
```

### Verify Installation

```bash
hcloud --version
```

### Configuration

#### Method 1: Interactive Configuration (Recommended)

```bash
hcloud configure
```

Follow the prompts to enter:
- Access Key ID (AK)
- Secret Access Key (SK)
- Region (e.g., cn-north-4)

Credentials are encrypted and stored in `~/.hcloud/`. They are NOT exposed in command-line arguments.

#### Method 2: Environment Variables

```bash
export HW_ACCESS_KEY=<your-ak>
export HW_SECRET_KEY=<your-sk>
export HW_REGION_NAME=cn-north-4
```

⚠️ **Warning**: Environment variable credentials are passed as command-line arguments to hcloud, which may be visible in `ps aux` and shell history.

### Verify Configuration

```bash
# Safe - does not expose credential values
hcloud configure list

# Test API connectivity
hcloud DNS ListPublicZones --cli-region=cn-north-4 --cli-output=json
```

## Dependency Installation

### jq (JSON Processor)

```bash
# Ubuntu/Debian
sudo apt install -y jq

# CentOS/RHEL
sudo yum install -y jq

# macOS
brew install jq
```

### curl

```bash
# Ubuntu/Debian
sudo apt install -y curl

# CentOS/RHEL
sudo yum install -y curl

# macOS (pre-installed)
```

### dig (DNS Lookup Tool)

```bash
# Ubuntu/Debian
sudo apt install -y dnsutils

# CentOS/RHEL
sudo yum install -y bind-utils

# macOS
brew install bind
```

### nslookup (Alternative DNS Lookup)

```bash
# Ubuntu/Debian
sudo apt install -y dnsutils

# CentOS/RHEL
sudo yum install -y bind-utils
```

## Troubleshooting

### hcloud CLI Not Found

```bash
# Check if installed
which hcloud

# If not found, add to PATH
export PATH="$PATH:~/.local/bin"

# Reinstall
curl -sSL https://hwcloudcli.obs.cn-north-1.myhuaweicloud.com/cli/latest/hcloud_install.sh | bash
```

### Authentication Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `InvalidAccessKeyId` | Wrong AK | Reconfigure with `hcloud configure` |
| `SignatureDoesNotMatch` | Wrong SK | Reconfigure with `hcloud configure` |
| `TokenExpiredException` | STS token expired | Obtain new temporary credentials |

### Network Issues

```bash
# Test connectivity to Huawei Cloud API
curl -sI https://dns.myhuaweicloud.com/

# If behind proxy, configure hcloud proxy
hcloud configure set --cli-proxy=http://proxy:port
```

### Version Update

```bash
# Check current version
hcloud --version

# Update to latest
hcloud update
```
