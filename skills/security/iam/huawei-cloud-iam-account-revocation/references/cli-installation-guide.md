# CLI Installation Guide

## Install KooCLI (hcloud)

### Linux / macOS
Follow the [official KooCLI installation guide](https://support.huaweicloud.com/qs-hcli/hcli_02_003.html) for the latest version:

```bash
# Download the installation script
curl -sSL https://cli-huawei.obs.cn-north-1.myhuaweicloud.com/install.sh -o /tmp/install-hcloud.sh

# Verify the script (optional: compare SHA256 against official release checksums)
# sha256sum /tmp/install-hcloud.sh

# Execute installation
bash /tmp/install-hcloud.sh

# Remove the script after installation
rm -f /tmp/install-hcloud.sh
```

> **Security note:** For production environments, download the offline package from the [Huawei Cloud official site](https://support.huaweicloud.com/qs-hcli/hcli_02_003.html) and verify the package checksum before installation.

### Verify Installation
```bash
hcloud version
```

## Configure Authentication

### Configure with AK/SK
```bash
hcloud configure set \
  --cli-profile=default \
  --access-key={YOUR_ACCESS_KEY} \
  --secret-key={YOUR_SECRET_KEY} \
  --cli-region=cn-north-4
```

### Verify Authentication
```bash
hcloud IAM ListUsersV5 --cli-region=cn-north-4 --limit=5
```

## Uninstall
```bash
hcloud uninstall
```