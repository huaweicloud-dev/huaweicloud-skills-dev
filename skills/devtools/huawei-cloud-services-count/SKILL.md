---
name: huawei-cloud-services-count
description: |
  Query the total number of Huawei Cloud services available through KooCLI offline metadata.
  Returns the count of all supported cloud services from the cached service catalog.
  Triggers include: "how many Huawei Cloud services", "count Huawei Cloud services", "华为云服务总数", "华为云有多少个服务", "查询华为云服务数量".
tags:
  - huawei-cloud
  - query
  - services
  - count
  - kocli
---

# Huawei Cloud Services Count

## Overview

This Skill queries how many Huawei Cloud services are available through the KooCLI offline metadata cache. It reads the local `services_en.json` file downloaded by `hcloud meta download`, parses the service entries, and returns the total count. No network API calls are needed after the initial metadata download.

**Use case**: Quickly determine how many cloud services Huawei Cloud offers at a glance, useful for reporting, documentation, or capacity awareness.

## Prerequisites

1. **KooCLI (hcloud)** installed and configured with valid AK/SK credentials
2. Python 3.6+ available for JSON parsing
3. KooCLI offline metadata must be downloaded at least once (`hcloud meta download`)

## Workflow

```
1. Refresh metadata → hcloud meta download
2. Parse local JSON → Read ~/.hcloud/metaRepo/services_en.json
3. Count entries → Count the items in the services array
4. Output → Print the total number of services
```

## Core Commands

### Refresh metadata and count services

Run the following command to refresh the offline metadata and output the total service count:

```bash
echo "y" | hcloud meta download && python3 -c "
import json
import os

meta_path = os.path.expanduser('~/.hcloud/metaRepo/services_en.json')
with open(meta_path) as f:
    data = json.load(f)

items = data.get('items', [])
seen = set()
unique_count = 0
for item in items:
    text = item['Service']['Text']
    if text not in seen:
        seen.add(text)
        unique_count += 1

print(f'Huawei Cloud Services Count: {len(items)} total entries, {unique_count} unique services')
"
```

### Count services only (skip download if metadata is recent)

If metadata was already downloaded recently, you can skip the download step:

```bash
python3 -c "
import json, os
meta_path = os.path.expanduser('~/.hcloud/metaRepo/services_en.json')
with open(meta_path) as f:
    data = json.load(f)
items = data.get('items', [])
print(f'Huawei Cloud Services Count: {len(items)}')
"
```

## Parameter Confirmation

| Parameter | Required | Description | Default |
|-----------|----------|-------------|---------|
| `{region}` | No | Huawei Cloud region (not required for meta commands) | `cn-north-4` |
| `{skip_download}` | No | Skip metadata refresh if cache is recent | `false` |

## Reference Documents

- [CLI Installation Guide](./references/cli-installation-guide.md) — KooCLI installation and configuration
- [IAM Policies](./references/iam-policies.md) — Required IAM permissions
- [Verification Method](./references/verification-method.md) — How to verify the skill works
- [Data Flow Diagram](./references/dataflow-diagram.md) — Mermaid data flow
- [Acceptance Criteria](./references/acceptance-criteria.md) — Success criteria

## KooCLI Command Format Standard

```bash
hcloud meta download
```

- **Service**: Not applicable — `meta` is a KooCLI system command, not a service-specific command
- **Operation**: `download` — lower case (system operation)
- **Confirmation**: Pipe `echo "y" |` to auto-confirm the overwrite prompt