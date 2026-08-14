#!/usr/bin/env bash
# Test CLI commands for huawei-cloud-vpcep-list skill.
# Usage: bash scripts/test-cli-commands.sh <skill-path> [cli|sdk]
set -uo pipefail

SKILL_PATH="${1:-skills/network/vpcep/huawei-cloud-vpcep-list}"
EXECUTOR="${2:-cli}"
REGION="${VPCEP_REGION:-cn-north-4}"

PASS=0
FAIL=0
FAILED_CASES=()

check() {
  local desc="$1"; shift
  if "$@" >/tmp/vpcep_test_out.log 2>&1; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc"
    echo "  output: $(tail -5 /tmp/vpcep_test_out.log | tr '\n' ' ')"
    FAIL=$((FAIL+1))
    FAILED_CASES+=("$desc")
  fi
}

echo "== VPCEP List Skill Tests (executor=$EXECUTOR, region=$REGION) =="

WRAPPER="$SKILL_PATH/scripts/list_vpcep.py"

if [ "$EXECUTOR" = "cli" ] || [ "$EXECUTOR" = "all" ]; then
  check "ListEndpoints returns endpoint list" \
    hcloud VPCEP ListEndpoints --cli-region="$REGION" --limit=5 --cli-output=json
  check "ListEndpoints name extraction (jq)" \
    bash -c "hcloud VPCEP ListEndpoints --cli-region=$REGION --limit=5 --cli-output=json | jq -e '.endpoints | type == \"array\"'"
  check "ListEndpoints with limit/offset pagination" \
    hcloud VPCEP ListEndpoints --cli-region="$REGION" --limit=5 --offset=0 --cli-output=json
  check "ListEndpointService returns service list" \
    hcloud VPCEP ListEndpointService --cli-region="$REGION" --limit=5 --cli-output=json
  check "ListEndpointService name extraction (jq)" \
    bash -c "hcloud VPCEP ListEndpointService --cli-region=$REGION --limit=5 --cli-output=json | jq -e '.endpoint_services | type == \"array\"'"
  check "ListEndpointService with status filter" \
    hcloud VPCEP ListEndpointService --cli-region="$REGION" --limit=5 --status=available --cli-output=json
  check "Wrapper: endpoint names-only" \
    bash -c "SKILL_QUALITY_DISABLE=1 python3 $WRAPPER --region=$REGION --names-only"
  check "Wrapper: services names-only" \
    bash -c "SKILL_QUALITY_DISABLE=1 python3 $WRAPPER --region=$REGION --resource-type services --names-only"
  check "Wrapper: endpoints json output" \
    bash -c "SKILL_QUALITY_DISABLE=1 python3 $WRAPPER --region=$REGION --limit 3 | jq -e '.name != null'"
fi

if [ "$EXECUTOR" = "sdk" ] || [ "$EXECUTOR" = "all" ]; then
  check "SDK list_endpoints" python3 -c "
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkvpcep.v1 import VpcepClient, ListEndpointsRequest
from huaweicloudsdkvpcep.v1.region.vpcep_region import VpcepRegion
creds = BasicCredentials(os.environ['HUAWEICLOUD_SDK_AK'], os.environ['HUAWEICLOUD_SDK_SK'])
client = VpcepClient.new_builder().with_credentials(creds).with_region(VpcepRegion.value_of('$REGION')).build()
resp = client.list_endpoints(ListEndpointsRequest(limit=5))
assert hasattr(resp, 'endpoints'), 'no endpoints attr'
print('SDK endpoints:', len(resp.endpoints) if resp.endpoints else 0)
"
  check "SDK list_endpoint_service" python3 -c "
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkvpcep.v1 import VpcepClient, ListEndpointServiceRequest
from huaweicloudsdkvpcep.v1.region.vpcep_region import VpcepRegion
creds = BasicCredentials(os.environ['HUAWEICLOUD_SDK_AK'], os.environ['HUAWEICLOUD_SDK_SK'])
client = VpcepClient.new_builder().with_credentials(creds).with_region(VpcepRegion.value_of('$REGION')).build()
resp = client.list_endpoint_service(ListEndpointServiceRequest(limit=5))
assert hasattr(resp, 'endpoint_services'), 'no endpoint_services attr'
print('SDK services:', len(resp.endpoint_services) if resp.endpoint_services else 0)
"
  check "Wrapper SDK executor" \
    bash -c "SKILL_QUALITY_DISABLE=1 python3 $WRAPPER --region=$REGION --resource-type endpoints --limit 3 --executor sdk"
  check "Wrapper SDK executor (services, no crash on model objects)" \
    bash -c "SKILL_QUALITY_DISABLE=1 python3 $WRAPPER --region=$REGION --resource-type services --limit 3 --executor sdk >/dev/null 2>&1"
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
