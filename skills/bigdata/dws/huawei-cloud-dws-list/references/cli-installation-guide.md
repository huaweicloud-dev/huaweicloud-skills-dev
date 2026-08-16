# CLI Installation Guide

This skill uses KooCLI (hcloud). Below are the installation and authentication steps.

## 1. Install KooCLI

```bash
# Download and install (Linux x86_64)
curl -sSL https://hwcloudcli.obs.cn-north-1.myhuaweicloud.com/cli/latest/hcloud_install.sh -o hcloud_install.sh
bash hcloud_install.sh

# Or via pip
pip3 install huaweicloudcli

# Verify
hcloud version
```

## 2. Configure Authentication (AK/SK)

```bash
hcloud configure set --cli-profile=default --cli-mode=AKSK --cli-access-key=<your-ak> --cli-secret-key=<your-sk> --cli-region=cn-north-4
```

> **Security**: Never share AK/SK values. Use an IAM user with least-privilege permissions (see `iam-policies.md`).

## 3. Verify Configuration

```bash
hcloud configure list
```

## 4. Verify DWS Service Availability

```bash
hcloud DWS --help
hcloud DWS ListClusters --help
```
