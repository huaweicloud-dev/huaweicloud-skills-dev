#!/usr/bin/env bash
# test-cli-commands.sh — functional smoke test for huawei-cloud-vpc-list
set -uo pipefail

SKILL_PATH="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
REGION="${HUAWEI_CLOUD_REGION:-cn-north-4}"

pass=0
fail=0
skip=0

run_test() {
    local id="$1" name="$2" cmd="$3"
    echo -n "  [$id] $name ... "
    if output=$(bash -c "$cmd" 2>&1); then
        echo "PASS"
        pass=$((pass + 1))
    else
        echo "FAIL"
        echo "    Error: $output"
        fail=$((fail + 1))
    fi
}

echo "=== VPC List Skill Tests (region: $REGION) ==="
echo

# Prerequisite check
if ! command -v hcloud &>/dev/null; then
    echo "SKIP: hcloud CLI not available"
    skip=$((skip + 5))
    exit 0
fi

run_test "TC-01" "VPC ListVpcs v3 help" "hcloud VPC ListVpcs/v3 --cli-region=$REGION --help >/dev/null 2>&1"
run_test "TC-02" "List VPCs live (v3, limit=3)" "hcloud VPC ListVpcs/v3 --cli-region=$REGION --limit=3 --cli-output=json >/dev/null 2>&1"
run_test "TC-03" "List VPCs live (v2, limit=2)" "hcloud VPC ListVpcs/v2 --cli-region=$REGION --limit=2 --cli-output=json >/dev/null 2>&1"
run_test "TC-04" "Filter VPCs by name (v3)" "hcloud VPC ListVpcs/v3 --cli-region=$REGION --limit=5 --name.1=tf-web-vpc --cli-output=json >/dev/null 2>&1"
run_test "TC-05" "SDK VpcClient importable" "python3 -c \"from huaweicloudsdkvpc.v3 import VpcClient; print('SDK OK')\" >/dev/null 2>&1"

echo
echo "=== Results: $pass passed, $fail failed, $skip skipped ==="
if [ "$fail" -gt 0 ]; then
    exit 1
fi
exit 0
