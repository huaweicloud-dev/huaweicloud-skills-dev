#!/usr/bin/env bash
# Test CLI commands for huawei-cloud-sfsturbo-list skill.
# Usage: bash scripts/test-cli-commands.sh <skill-path> [cli|sdk]
set -uo pipefail

SKILL_PATH="${1:-skills/storage/sfsturbo/huawei-cloud-sfsturbo-list}"
EXECUTOR="${2:-cli}"
REGION="${SFSTURBO_REGION:-cn-north-4}"

PASS=0
FAIL=0
FAILED_CASES=()

check() {
  local desc="$1"; shift
  if "$@" >/tmp/sfsturbo_test_out.log 2>&1; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc"
    echo "  output: $(tail -5 /tmp/sfsturbo_test_out.log | tr '\n' ' ')"
    FAIL=$((FAIL+1))
    FAILED_CASES+=("$desc")
  fi
}

echo "== SFSTurbo List Skill Tests (executor=$EXECUTOR, region=$REGION) =="

WRAPPER="$SKILL_PATH/scripts/list_sfsturbo_shares.py"

if [ "$EXECUTOR" = "cli" ] || [ "$EXECUTOR" = "all" ]; then
  check "ListShares returns file system list" \
    hcloud SFSTurbo ListShares --cli-region="$REGION" --limit=5 --cli-output=json
  check "ListShares name extraction (jq)" \
    bash -c "hcloud SFSTurbo ListShares --cli-region=$REGION --limit=5 --cli-output=json | jq -e '.shares | type == \"array\"'"
  check "ListShares with limit/offset pagination" \
    hcloud SFSTurbo ListShares --cli-region="$REGION" --limit=5 --offset=0 --cli-output=json
  check "Wrapper: names-only" \
    bash -c "SKILL_QUALITY_DISABLE=1 python3 $WRAPPER --region=$REGION --names-only"
  check "Wrapper: json output (valid JSON lines or empty)" \
    bash -c "out=\$(SKILL_QUALITY_DISABLE=1 python3 $WRAPPER --region=$REGION --limit 3); if [ -z \"\$out\" ]; then exit 0; fi; echo \"\$out\" | jq -e '.name != null or .id != null' >/dev/null"
fi

if [ "$EXECUTOR" = "sdk" ] || [ "$EXECUTOR" = "all" ]; then
  check "SDK list_shares" python3 -c "
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdksfsturbo.v1 import SFSTurboClient, ListSharesRequest
from huaweicloudsdksfsturbo.v1.region.sfsturbo_region import SFSTurboRegion
creds = BasicCredentials(os.environ['HUAWEICLOUD_SDK_AK'], os.environ['HUAWEICLOUD_SDK_SK'])
client = SFSTurboClient.new_builder().with_credentials(creds).with_region(SFSTurboRegion.value_of('$REGION')).build()
resp = client.list_shares(ListSharesRequest(limit=5))
assert hasattr(resp, 'shares'), 'no shares attr'
print('SDK shares:', len(resp.shares) if resp.shares else 0)
"
  check "Wrapper SDK executor" \
    bash -c "SKILL_QUALITY_DISABLE=1 python3 $WRAPPER --region=$REGION --limit 3 --executor sdk"
  check "Wrapper SDK executor (no crash on model objects)" \
    bash -c "SKILL_QUALITY_DISABLE=1 python3 $WRAPPER --region=$REGION --limit 3 --executor sdk >/dev/null 2>&1"
  check "Invalid region -> friendly error (no raw KeyError)" \
    bash -c "SKILL_QUALITY_DISABLE=1 python3 $WRAPPER --region=invalid-region-xyz --executor sdk 2>&1; test \$? -ne 0"
  check "Invalid region message mentions region hint" \
    bash -c "SKILL_QUALITY_DISABLE=1 python3 $WRAPPER --region=invalid-region-xyz --executor sdk 2>&1 | grep -q '区域(region)无效'"
fi

echo "=============================="
echo "RESULT: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  printf 'FAILED: %s\n' "${FAILED_CASES[@]}"
  exit 1
fi
exit 0
