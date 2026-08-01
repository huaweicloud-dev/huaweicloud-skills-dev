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

echo "=== IAM Role List Skill Tests (executor: $EXECUTOR, region: $REGION) ==="
echo

if [ "$EXECUTOR" = "cli" ]; then
    run_cli_test "TC-01" "ListRoles (full)" "hcloud IAM KeystoneListPermissions --cli-region=$REGION"
    run_cli_test "TC-02" "ListRoles (JSON output)" "hcloud IAM KeystoneListPermissions --cli-region=$REGION --cli-output=json"
    run_cli_test "TC-03" "ListRoles (type filter)" "hcloud IAM KeystoneListPermissions --cli-region=$REGION --permission_type=role"
    run_cli_test "TC-04" "ListRoles (catalog filter)" "hcloud IAM KeystoneListPermissions --cli-region=$REGION --permission_type=role --catalog=CCE"
elif [ "$EXECUTOR" = "sdk" ]; then
    echo "SDK tests require Python with huaweicloudsdkiam installed and HUAWEI_CLOUD_ACCESS_KEY/HUAWEI_CLOUD_SECRET_KEY/HUAWEI_CLOUD_DOMAIN_ID set."
    run_sdk_test "TC-01" "ListRoles (SDK)" "
import os
from huaweicloudsdkcore.auth.credentials import GlobalCredentials
from huaweicloudsdkiam.v3 import IamClient
from huaweicloudsdkiam.v3.model import KeystoneListPermissionsRequest
from huaweicloudsdkiam.v3.region.iam_region import IamRegion
creds = GlobalCredentials(os.environ['HUAWEI_CLOUD_ACCESS_KEY'], os.environ['HUAWEI_CLOUD_SECRET_KEY']).with_domain_id(os.environ['HUAWEI_CLOUD_DOMAIN_ID'])
client = IamClient.new_builder().with_credentials(creds).with_region(IamRegion.value_of('$REGION')).build()
resp = client.keystone_list_permissions(KeystoneListPermissionsRequest())
roles = resp.roles or []
print('Role number:', len(roles))
"
else
    echo "Unknown executor — use CLI or SDK."
    skip=4
fi

echo
echo "=== Results: $pass passed, $fail failed, $skip skipped ==="
if [ "$fail" -gt 0 ]; then
    exit 1
fi
exit 0
