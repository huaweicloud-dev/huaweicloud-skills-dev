# KooCLI Installation Guide

## Install hcloud (KooCLI)

KooCLI is the Huawei Cloud CLI used by this skill. Install it on Linux/macOS:

```bash
curl -sSL https://cn-north-4-hcli-cloud.obs.cn-north-4.myhuaweicloud.com/hcli/install.sh | bash
```

Or use the package manager (Windows: `choco install hcloud`, macOS: `brew install hcloud`).

Verify:

```bash
hcloud version
```

## Authentication

Configure AK/SK (an IAM user with at least `RDS ReadOnlyAccess`):

```bash
hcloud configure set --cli-my-profile=default \
  --cli-access-key=your-ak --cli-secret-key=your-sk
hcloud configure set --cli-region=cn-north-4
```

**Note:** for security, prefer environment variables in agent/CI contexts
(never hardcode credentials in files):

```bash
export HUAWEI_ACCESS_KEY=your-ak
export HUAWEI_SECRET_KEY=your-sk
export HUAWEICLOUD_SDK_AK=your-ak
export HUAWEICLOUD_SDK_SK=your-sk
```

## Verify the CLI can reach RDS

```bash
hcloud RDS ListInstances --cli-region=cn-north-4 --limit=5 --cli-output=json
```

If the command returns the `instances` array (possibly empty), the CLI is
authenticated and ready. If you see `[USE_ERROR]`, `error_msg` or a
`403/401`, check the AK/SK and the IAM policy (`rds:instance:list` or
`RDS ReadOnlyAccess`).

## SDK fallback (optional)

The wrapper script `scripts/list_rds_instances.py` falls back to the Python
SDK when the CLI is unavailable:

```bash
pip install huaweicloudsdkcore huaweicloudsdkrds
```

The SDK reads the same `HUAWEI_ACCESS_KEY` / `HUAWEI_SECRET_KEY` environment
variables (or `HUAWEICLOUD_SDK_AK` / `HUAWEICLOUD_SDK_SK`).
