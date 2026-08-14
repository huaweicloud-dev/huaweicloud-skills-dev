# CLI Installation and Authentication Guide

## 1. Install KooCLI (hcloud)

KooCLI (hcloud) is the official Huawei Cloud command-line tool.

### Install via script (Linux / macOS / Windows Git Bash)

```bash
curl -fsSL https://hwcloudcli.obs.cn-north-1.myhuaweicloud.com/cli/latest/hcloud_install.sh -o hcloud_install.sh
bash hcloud_install.sh
```

### Verify installation

```bash
hcloud version
```

Expected output example: `Current KooCLI version: 7.2.12`

> **Architecture note:** The installer selects the correct binary for your platform. On ARM (aarch64) Linux, ensure you use the ARM build; an x86-64 binary will fail with `Exec format error` on ARM machines.

## 2. Configure Credentials

### 2.1 Interactive configuration (recommended)

```bash
hcloud configure
```

Follow the prompts to enter:

- Access Key ID (AK)
- Secret Access Key (SK)
- Region (e.g., `cn-north-4`)
- Project ID (optional; can be auto-resolved)

### 2.2 Environment variables

```bash
export HUAWEICLOUD_SDK_AK=<your-access-key-id>
export HUAWEICLOUD_SDK_SK=<your-access-key-secret>
```

### 2.3 Verify configuration

```bash
hcloud configure list
```

Expected: a profile with `mode: AKSK` and a non-empty `accessKeyId`.

## 3. Credentials Security Rules

- **Never** hardcode AK/SK in skill scripts or documents.
- **Never** ask the user to paste AK/SK into the conversation.
- Read credentials only from the configured CLI profile or environment variables.
- If the user attempts to share AK/SK directly, refuse and point them to the secure configuration methods above.

## 4. Get Your AK/SK

1. Log in to the Huawei Cloud console.
2. Go to **My Credentials** (用户名 > 我的凭证) or the IAM console.
3. Under **Access Keys**, create / view an access key pair.
4. Keep the Secret Access Key private — it is shown only once at creation.
