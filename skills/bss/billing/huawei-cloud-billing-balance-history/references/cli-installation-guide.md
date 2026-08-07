# CLI Installation Guide

> **Note:** the KooCLI (`hcloud`) does **not** support the BSS service
> (`hcloud BSS` returns "Unsupported service: BSS"). This skill therefore uses
> the **Python SDK** as its only execution path. This guide covers SDK
> installation and authentication.

## Install the Python SDK

```bash
pip install huaweicloudsdkbss huaweicloudsdkcore
```

Requires Python 3.8+.

## Configure Authentication (AK/SK)

The skill reads credentials from environment variables. Do **not** hardcode
credentials into any file:

```bash
export HUAWEI_ACCESS_KEY="<your-ak>"
export HUAWEI_SECRET_KEY="<your-sk>"
```

Alternatively the Huawei Cloud SDK standard variables are also supported:

```bash
export HUAWEICLOUD_SDK_AK="<your-ak>"
export HUAWEICLOUD_SDK_SK="<your-sk>"
```

> The AK/SK must belong to the account whose balance you want to query.

## Verify the Installation

```bash
python3 -c "from huaweicloudsdkbss.v2 import BssClient; print('BSS SDK OK')"
```

Then run the skill:

```bash
cd <skill-dir>
python3 scripts/query_balance_history.py --action balance
```

## Global Service Note

BSS is a **global service** — no region parameter is required. The SDK client
must use `GlobalCredentials` with the explicit endpoint
`https://bss.myhuaweicloud.com` (already handled by
`scripts/query_balance_history.py`).
