---
name: huawei-cloud-obs-list-excel
description: Query OBS bucket and object listings, then export them to an Excel (.xlsx) report. Triggers include: "list OBS buckets", "export OBS to Excel", "OBS inventory", "列出OBS存储桶", "导出OBS列表", "OBS报表".
tags:
  - huawei-cloud
  - obs
  - storage
  - excel
  - listing
---

# huawei-cloud-obs-list-excel

## Overview

This skill retrieves a list of all OBS (Object Storage Service) buckets and their objects from a specified Huawei Cloud region, then generates an Excel (.xlsx) file containing the inventory data. It uses the `huaweicloudsdkobs` SDK to query cloud resources and `openpyxl` to produce the spreadsheet.

**Applicable scenarios:**
- Daily OBS resource inventory and audit
- Backup and storage usage analysis
- OBS asset management reporting
- Storage cost review preparation

## Prerequisites

1. **Python 3.8+** with required packages:
   - `huaweicloudsdkobs` (≥3.1.209)
   - `huaweicloudsdkcore` (≥3.1.209)
   - `openpyxl` (≥3.1.0)
2. **Huawei Cloud AK/SK** configured via environment variables:
   - `HUAWEI_CLOUD_ACCESS_KEY` — Access Key ID
   - `HUAWEI_CLOUD_SECRET_KEY` — Secret Access Key
   - Or automatically detected from any `HUAWEI`/`HW`/`HWC` prefixed variables containing `ACCESS_KEY`/`_AK` / `SECRET_KEY`/`_SK`
3. **IAM permissions**: The AK/SK must have the `obs:bucket:ListAllMyBuckets` and `obs:object:ListObject` permissions.

## Workflow

```
1. Initialize OBS client with region and credentials
2. Call list_buckets() to get all buckets
3. For each bucket, call list_objects() with max_keys=1000
4. Aggregate bucket and object data into a structured report
5. Write the data to an Excel (.xlsx) file with formatted sheets
6. Report the file path to the agent or user
```

## Core Commands

### List OBS buckets and export to Excel

```bash
python3 scripts/obs-list-excel.py --region cn-north-4 --output /tmp/obs-inventory.xlsx
```

| Param | Required | Description | Default |
|-------|----------|-------------|---------|
| `--region` | Yes | Huawei Cloud region (e.g. cn-north-4, cn-east-3) | — |
| `--output` | No | Output Excel file path | `./obs-inventory.xlsx` |
| `--bucket-type` | No | Filter: `OBJECT`, `POSIX`, or empty (all) | `""` |
| `--max-keys` | No | Max objects per bucket to list | `1000` |

### Example: Query current account buckets
```bash
python3 scripts/obs-list-excel.py --region=cn-north-4 --output=/tmp/obs-report.xlsx
```

### View existing Excel report
```bash
python3 -c "
import openpyxl
wb = openpyxl.load_workbook('/tmp/obs-report.xlsx')
for sheet_name in wb.sheetnames:
    ws = wb[sheet_name]
    print(f'Sheet: {sheet_name} ({ws.max_row} rows, {ws.max_column} cols)')
    for row in wws.iter_rows(max_row=5, values_only=True):
        print(row)
"
```

## Parameter Confirmation

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `{region}` | Yes | Huawei Cloud region | `cn-north-4`, `cn-east-east-2` |
| `{output}` | No | Output Excel path | `/tmp/obs-inventory.xlsx` |
| `{max-keys}` | No | Max objects to list per bucket call | `1000` |

## Reference Documents

- [IAM Policies](references/iam-policies.md) — Required IAM permissions
- [Data Flow Diagram](references/dataflow-diagram.md) — Mermaid flowchart
- [Verification Method](references/verification-method.md) — How to verify the skill

## KooCLI Command Format Standard

CLI commands are NOT available for OBS on `hcloud`. This skill uses the **Python SDK** (`huaweicloudsdkobs`) instead. See `references/cli-installation-guide.md` for SDK setup.