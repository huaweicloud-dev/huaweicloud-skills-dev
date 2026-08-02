#!/usr/bin/env bash
set -euo pipefail

SKILL_PATH="${1:?Usage: test-cli-commands.sh <skill-path> [--executor cli|sdk]}"
EXECUTOR="cli"
if [ "${2:-}" = "--executor" ] && [ -n "${3:-}" ]; then
    EXECUTOR="$3"
fi
REGION="${HUAWEI_CLOUD_REGION:-cn-north-4}"

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

echo "=== EIP List Skill Tests (executor: $EXECUTOR, region: $REGION) ==="
echo

if [ "$EXECUTOR" = "cli" ]; then
    run_cli_test "TC-01" "ListPublicips (full)" "hcloud EIP ListPublicips --cli-region=$REGION"
    run_cli_test "TC-02" "ListPublicips (JSON output)" "hcloud EIP ListPublicips --cli-region=$REGION --cli-output=json"
    run_cli_test "TC-03" "ListPublicips (id filter)" "hcloud EIP ListPublicips --cli-region=$REGION --id.1=test"
    run_cli_test "TC-04" "ListPublicips (ip_version filter)" "hcloud EIP ListPublicips --cli-region=$REGION --ip_version.1=4"
    run_cli_test "TC-05" "ListPublicips/v2 (limit)" "hcloud EIP ListPublicips/v2 --cli-region=$REGION --limit=10"
elif [ "$EXECUTOR" = "sdk" ]; then
    echo "SDK tests require Python with huaweicloudsdkeip installed and HUAWEI_CLOUD_ACCESS_KEY/HUAWEI_CLOUD_SECRET_KEY set."
    run_sdk_test "TC-01" "ListPublicips (SDK)" "
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkeip.v2 import EipClient
from huaweicloudsdkeip.v2.model import ListPublicipsRequest
from huaweicloudsdkeip.v2.region.eip_region import EipRegion
creds = BasicCredentials(os.environ['HUAWEI_CLOUD_ACCESS_KEY'], os.environ['HUAWEI_CLOUD_SECRET_KEY'])
client = EipClient.new_builder().with_credentials(creds).with_region(EipRegion.value_of('$REGION')).build()
resp = client.list_publicips(ListPublicipsRequest())
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
