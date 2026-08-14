#!/usr/bin/env bash
# test-cli-commands.sh — functional smoke test for huawei-cloud-obs-file-count
set -uo pipefail

SKILL_PATH="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
REGION="${HUAWEI_CLOUD_REGION:-cn-north-4}"
BUCKET="${TEST_OBS_BUCKET:-obs-hd-dev-static}"

pass=0
fail=0
skip=0

SCRIPT="$SKILL_PATH/scripts/count_obs_files.py"

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

run_expected() {
    local id="$1" name="$2" expected="$3" cmd="$4"
    echo -n "  [$id] $name ... "
    if output=$(bash -c "$cmd" 2>&1) && [ "$output" = "$expected" ]; then
        echo "PASS"
        pass=$((pass + 1))
    else
        echo "FAIL"
        echo "    Expected: $expected"
        echo "    Got:      $output"
        fail=$((fail + 1))
    fi
}

run_exit_nonzero() {
    local id="$1" name="$2" needle="$3" cmd="$4"
    echo -n "  [$id] $name ... "
    out=$(bash -c "$cmd" 2>&1)
    rc=$?
    if [ "$rc" -ne 0 ] && echo "$out" | grep -q "$needle"; then
        echo "PASS"
        pass=$((pass + 1))
    else
        echo "FAIL"
        echo "    Expected exit!=0 and stderr containing: $needle"
        echo "    Got exit=$rc: $out"
        fail=$((fail + 1))
    fi
}

echo "=== OBS File Count Skill Tests (region: $REGION, bucket: $BUCKET) ==="
echo

# Prerequisite check
if ! command -v python3 &>/dev/null; then
    echo "SKIP: python3 not available"
    skip=$((skip + 8))
    exit 0
fi

# TC-01: whole-bucket count via CLI (auto)
run_test "TC-01" "Whole-bucket file count (CLI auto)" \
    "python3 '$SCRIPT' --bucket '$BUCKET' | grep -E '^[0-9]+$'"

# TC-02: count under prefix
PREFIX_COUNT=$(python3 "$SCRIPT" --bucket "$BUCKET" --prefix openplatform 2>/dev/null)
if [ -n "$PREFIX_COUNT" ] && echo "$PREFIX_COUNT" | grep -qE '^[0-9]+$'; then
    echo "  [TC-02] File count under prefix (CLI auto) ... PASS ($PREFIX_COUNT)"
    pass=$((pass + 1))
else
    echo "  [TC-02] File count under prefix (CLI auto) ... FAIL (got: $PREFIX_COUNT)"
    fail=$((fail + 1))
fi

# TC-03: prefix with trailing slash matches TC-02
SLASH_COUNT=$(python3 "$SCRIPT" --bucket "$BUCKET" --prefix openplatform/ 2>/dev/null)
if [ -n "$SLASH_COUNT" ] && [ "$SLASH_COUNT" = "$PREFIX_COUNT" ]; then
    echo "  [TC-03] Prefix with trailing slash ... PASS ($SLASH_COUNT)"
    pass=$((pass + 1))
else
    echo "  [TC-03] Prefix with trailing slash ... FAIL (expected $PREFIX_COUNT, got $SLASH_COUNT)"
    fail=$((fail + 1))
fi

# TC-04: SDK path matches CLI
SDK_COUNT=$(python3 "$SCRIPT" --bucket "$BUCKET" --prefix openplatform --executor sdk 2>/dev/null)
if [ -n "$SDK_COUNT" ] && [ "$SDK_COUNT" = "$PREFIX_COUNT" ]; then
    echo "  [TC-04] File count under prefix (SDK) ... PASS ($SDK_COUNT)"
    pass=$((pass + 1))
else
    echo "  [TC-04] File count under prefix (SDK) ... FAIL (expected $PREFIX_COUNT, got $SDK_COUNT)"
    fail=$((fail + 1))
fi

# TC-05: empty prefix returns 0
run_expected "TC-05" "Empty prefix returns 0" "0" \
    "python3 '$SCRIPT' --bucket '$BUCKET' --prefix nonexistent-prefix-xyz"

# TC-06: nonexistent bucket error (auto)
run_exit_nonzero "TC-06" "Nonexistent bucket error (auto)" "NoSuchBucket" \
    "python3 '$SCRIPT' --bucket no-such-bucket-xyz"

# TC-07: nonexistent bucket error (SDK)
run_exit_nonzero "TC-07" "Nonexistent bucket error (SDK)" "NoSuchBucket" \
    "python3 '$SCRIPT' --bucket no-such-bucket-xyz --executor sdk"

# TC-08: SDK availability check
run_test "TC-08" "SDK availability check" \
    "python3 -c \"from huaweicloudsdkobs.v1.obs_client import ObsClient; print('SDK OK')\""

echo
echo "=== Results: $pass passed, $fail failed, $skip skipped ==="
[ "$fail" -eq 0 ]
