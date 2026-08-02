#!/usr/bin/env bash
set -euo pipefail

SKILL_PATH="${1:?Usage: test-cli-commands.sh <skill-path> [--executor cli|sdk]}"
EXECUTOR="cli"
if [ "${2:-}" = "--executor" ] && [ -n "${3:-}" ]; then
    EXECUTOR="$3"
fi
REGION="${HUAWEI_CLOUD_REGION:-cn-north-4}"
ECS_ID="${HUAWEI_CLOUD_ECS_ID:-}"
EIP_ID="${HUAWEI_CLOUD_EIP_ID:-}"

pass=0
fail=0
skip=0

run_cli_test() {
    local id="$1" name="$2" cmd="$3"
    echo -n "  [$id] $name ... "
    if ! command -v hcloud &>/dev/null; then
        echo "SKIP (hcloud not available)"
        skip=$((skip + 1))
        return
    fi
    if [ -z "$ECS_ID" ] && echo "$cmd" | grep -q '<ecs-id>'; then
        echo "SKIP (HUAWEI_CLOUD_ECS_ID not set)"
        skip=$((skip + 1))
        return
    fi
    if [ -z "$EIP_ID" ] && echo "$cmd" | grep -q '<eip-id>'; then
        echo "SKIP (HUAWEI_CLOUD_EIP_ID not set)"
        skip=$((skip + 1))
        return
    fi
    read -r -a cmd_args <<< "$cmd"
    if output=$("${cmd_args[@]}" 2>&1); then
        if echo "$output" | grep -q 'USE_ERROR'; then
            echo "FAIL (USE_ERROR)"
            echo "    Error: $output"
            fail=$((fail + 1))
        else
            echo "PASS"
            pass=$((pass + 1))
        fi
    else
        echo "FAIL"
        echo "    Error: $output"
        fail=$((fail + 1))
    fi
}

run_sdk_test() {
    local id="$1" name="$2" script="$3"
    echo -n "  [$id] $name ... "
    if output=$(python3 -c "$script" 2>&1); then
        echo "PASS"
        pass=$((pass + 1))
    else
        echo "FAIL"
        echo "    Error: $output"
        fail=$((fail + 1))
    fi
}

echo "=== ECS EIP Query Skill Tests (executor: $EXECUTOR, region: $REGION) ==="
echo

if [ "$EXECUTOR" = "cli" ]; then
    run_cli_test "TC-01" "ListPublicips by ECS device_id" "hcloud EIP ListPublicips/v3 --cli-region=$REGION --vnic.device_id.1=<ecs-id>"
    run_cli_test "TC-02" "ListPublicips by ECS device_id (JSON)" "hcloud EIP ListPublicips/v3 --cli-region=$REGION --vnic.device_id.1=<ecs-id> --cli-output=json"
    run_cli_test "TC-03" "ListServersDetails by name" "hcloud ECS ListServersDetails --cli-region=$REGION --name=test"
    run_cli_test "TC-04" "ShowServer detail" "hcloud ECS ShowServer --cli-region=$REGION --server_id=<ecs-id>"
    run_cli_test "TC-05" "ShowPublicip/v3 detail (real EIP)" "hcloud EIP ShowPublicip/v3 --cli-region=$REGION --publicip_id=${EIP_ID:-<eip-id>}"
elif [ "$EXECUTOR" = "sdk" ]; then
    echo "SDK tests require Python with huaweicloudsdkeip installed and HUAWEI_CLOUD_ACCESS_KEY/HUAWEI_CLOUD_SECRET_KEY set."
    run_sdk_test "TC-01" "ListPublicips by vnic_device_id (SDK)" "
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkeip.v3 import EipClient
from huaweicloudsdkeip.v3.model import ListPublicipsRequest
from huaweicloudsdkeip.v3.region.eip_region import EipRegion
creds = BasicCredentials(os.environ['HUAWEI_CLOUD_ACCESS_KEY'], os.environ['HUAWEI_CLOUD_SECRET_KEY'])
client = EipClient.new_builder().with_credentials(creds).with_region(EipRegion.value_of('$REGION')).build()
req = ListPublicipsRequest()
if os.environ.get('HUAWEI_CLOUD_ECS_ID'):
    req.vnic_device_id = [os.environ['HUAWEI_CLOUD_ECS_ID']]
resp = client.list_publicips(req)
eips = resp.publicips or []
print('EIP number:', len(eips))
"
else
    echo "Unknown executor — use CLI or SDK."
    skip=5
fi

echo
echo "=== Results: $pass passed, $fail failed, $skip skipped ==="
if [ "$fail" -gt 0 ]; then
    exit 1
fi
exit 0
