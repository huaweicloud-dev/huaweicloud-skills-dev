# CLI Installation Guide

## Install KooCLI

### Linux / macOS
```bash
curl -sSL https://cn-hangdu-1.obs.cn-north-4.myhuaweicloud.com/kocli/latest/hci_install.sh | bash
```

### Verify Installation
```bash
hcloud --version
```

## Configure Authentication
```bash
hcloud configure set --cli-access-key=YOUR_AK --cli-secret-key=YOUR_SK --cli-region=cn-north-4
```

## Download Metadata
```bash
echo "y" | hcloud meta download
```