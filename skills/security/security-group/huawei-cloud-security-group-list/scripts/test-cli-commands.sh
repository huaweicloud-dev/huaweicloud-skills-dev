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
        echo "PASS"
        pass=$((pass + 1))
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

echo "=== Security Group List Skill Tests (executor: $EXECUTOR, region: $REGION) ==="
echo

if [ "$EXECUTOR" = "cli" ]; then
    run_cli_test "TC-01" "ListSecurityGroups (full)" "hcloud VPC ListSecurityGroups --cli-region=$REGION"
    run_cli_test "TC-02" "ListSecurityGroups (JSON output)" "hcloud VPC ListSecurityGroups --cli-region=$REGION --cli-output=json"
    run_cli_test "TC-03" "ListSecurityGroups (name filter)" "hcloud VPC ListSecurityGroups --cli-region=$REGION --name.1=test"
    run_cli_test "TC-04" "ListSecurityGroups (id filter)" "hcloud VPC ListSecurityGroups --cli-region=$REGION --id.1=test"
    run_cli_test "TC-05" "ListSecurityGroups (limit)" "hcloud VPC ListSecurityGroups --cli-region=$REGION --limit=10"
elif [ "$EXECUTOR" = "sdk" ]; then
    echo "SDK tests require Python with huaweicloudsdkvpc installed and HUAWEI_CLOUD_ACCESS_KEY/HUAWEI_CLOUD_SECRET_KEY set."
    run_sdk_test "TC-01" "ListSecurityGroups (SDK)" "
import os
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkvpc.v3 import VpcClient
from huaweicloudsdkvpc.v3.model import ListSecurityGroupsRequest
from huaweicloudsdkvpc.v3.region.vpc_region import VpcRegion
creds = BasicCredentials(os.environ['HUAWEI_CLOUD_ACCESS_KEY'], os.environ['HUAWEI_CLOUD_SECRET_KEY'])
client = VpcClient.new_builder().with_credentials(creds).with_region(VpcRegion.value_of('$REGION')).build()
resp = client.list_security_groups(ListSecurityGroupsRequest())
groups = resp.security_groups or []
print('Security group number:', len(groups))
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
