# CLI Installation Guide

## Installing hcloud CLI (KooCLI)

### Linux / macOS

```bash
# Download and install
curl -sSL https://hwcloudcli.obs.cn-north-4.myhuaweicloud.com/cli/latest/hcloud_install.sh -o hcloud_install.sh
bash hcloud_install.sh

# Verify installation
hcloud --version
```

### Windows

```powershell
# Download installer
Invoke-WebRequest -Uri "https://hwcloudcli.obs.cn-north-4.myhuaweicloud.com/cli/latest/hcloud_install.exe" -OutFile "hcloud_install.exe"
.\hcloud_install.exe
```

## Authentication Configuration

### Interactive Mode (Recommended)

```bash
hcloud configure set --cli-profile=default \
  --cli-access-key=YOUR_AK \
  --cli-secret-key=YOUR_SK \
  --cli-region=cn-north-4
```

### Environment Variables (Alternative)

```bash
export HW_ACCESS_KEY="YOUR_AK"
export HW_SECRET_KEY="YOUR_SK"
export HW_REGION_NAME="cn-north-4"
```

## Verify Configuration

```bash
hcloud ECS ListServersDetails --cli-region=cn-north-4 --limit=1
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `command not found: hcloud` | Add hcloud to PATH or reinstall |
| `Authentication failed` | Check AK/SK correctness and expiration |
| `Region not found` | Use valid region name (e.g., cn-north-4) |
| `Permission denied` | Verify IAM policy grants required ECS read actions |
