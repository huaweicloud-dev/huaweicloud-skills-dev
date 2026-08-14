# CLI Installation Guide

This skill is CLI-first: it uses **KooCLI (hcloud)** to call the Huawei Cloud
RDS v3 API. The SDK fallback (`huaweicloudsdkrds`) is only needed when the
CLI is unavailable.

## 1. Install KooCLI (hcloud)

Reference: https://support.huaweicloud.com/qs-hcli/hcli_02_003.html

```bash
# Download and install (Linux x86_64 / ARM64):
curl -sSL https://hwcloudcli.obs.cn-north-1.myhuaweicloud.com/cli/latest/hcloud_install.sh -o hcloud_install.sh
bash hcloud_install.sh
```

Verify:

```bash
hcloud version
# KooCLI Version 7.2.x ...
```

## 2. Configure Authentication (AK/SK)

```bash
hcloud configure set --cli-profile=default --cli-mode=AKSK \
  --cli-access-key=<your-ak> --cli-secret-key=<your-sk> --cli-region=cn-north-4
```

Or use environment variables (no config file needed):

```bash
export HUAWEICLOUD_SDK_AK="<your-ak>"
export HUAWEICLOUD_SDK_SK="<your-sk>"
export HUAWEI_ACCESS_KEY="<your-ak>"   # used by the SDK fallback scripts
export HUAWEI_SECRET_KEY="<your-sk>"
```

> ⚠️ Never hardcode AK/SK into skill scripts or documents. Always read them
> from environment variables or the interactive `hcloud configure` flow.

Verify authentication:

```bash
hcloud RDS ListInstances --cli-region=cn-north-4 --limit=1
```

## 3. Check the RDS Service is Available

```bash
hcloud RDS --help
```

You should see all RDS operations (ListInstances, ShowReplicationStatus,
ShowStorageUsedSpace, ListSlowLogs, ListErrorLogsNew, ListConfigurations,
ShowInstanceConfiguration, ListBackups, CreateManualBackup,
StartInstanceRestartAction, ListInstanceDiagnosis, ...).

## 4. SDK Fallback (Optional)

Only required when the CLI is unavailable:

```bash
pip install huaweicloudsdkrds huaweicloudsdkcore
```

```python
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkrds.v3.region.rds_region import RdsRegion
from huaweicloudsdkrds.v3 import RdsClient, ListInstancesRequest

ak = os.getenv("HUAWEI_ACCESS_KEY") or os.getenv("HUAWEICLOUD_SDK_AK")
sk = os.getenv("HUAWEI_SECRET_KEY") or os.getenv("HUAWEICLOUD_SDK_SK")
client = RdsClient.new_builder() \
    .with_credentials(BasicCredentials(ak, sk)) \
    .with_region(RdsRegion.value_of("cn-north-4")) \
    .build()
resp = client.list_instances(ListInstancesRequest())
print([(i.name, i.id, i.status) for i in (resp.instances or [])])
```

## 5. Region & Project

- All commands take `--cli-region={region}` (default `cn-north-4`).
- The project ID is resolved automatically from the authenticated profile.
