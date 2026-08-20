#!/usr/bin/env bash
# Test CLI commands for huawei-cloud-obs-list-excel
# Usage: bash test-cli-commands.sh [--executor cli|sdk|api]

set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== huawei-cloud-obs-list-excel Test Suite ==="
echo ""

# Check help
echo "--- TC-01: help ---"
python3 "${SKILL_DIR}/scripts/obs-list-excel.py" --help && echo "PASS" || echo "FAIL"

echo ""
echo "--- TC-02: Check imports ---"
python3 -c "
from huaweicloudsdkobs.v1.obs_client import ObsClient
from huaweicloudsdkobs.v1.model.list_buckets_request import ListBucketsRequest
from huaweicloudsdkobs.v1.model.list_objects_request import ListObjectsRequest
from openpyxl import Workbook
print('All imports OK')
" && echo "PASS" || echo "FAIL"

echo ""
echo "--- TC-03: Check script syntax and quality SDK ---"
python3 -c "
import sys
sys.path.insert(0, '${SKILL_DIR}/scripts/')
from skill_quality_sdk import self_check
self_check()
" && echo "PASS" || echo "FAIL"

echo ""
echo "=== All tests done ==="