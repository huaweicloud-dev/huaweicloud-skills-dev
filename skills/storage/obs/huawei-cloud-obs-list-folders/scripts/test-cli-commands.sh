#!/usr/bin/env bash
# test-cli-commands.sh — functional smoke test for huawei-cloud-obs-list-folders
set -uo pipefail

SKILL_PATH="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
REGION="${HUAWEI_CLOUD_REGION:-cn-north-4}"
BUCKET="${TEST_OBS_BUCKET:-cts-obs-bucket-test}"

pass=0
fail=0
skip=0

SCRIPT="$SKILL_PATH/scripts/list_obs_folders.py"

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

echo "=== OBS List Folders Skill Tests (region: $REGION, bucket: $BUCKET) ==="
echo

# Prerequisite check
if ! command -v python3 &>/dev/null; then
    echo "SKIP: python3 not available"
    skip=$((skip + 10))
    exit 0
fi

# TC-01: list buckets via CLI (auto)
echo -n "  [TC-01] List OBS buckets (CLI auto) ... "
if output=$(python3 "$SCRIPT" --buckets-only 2>&1) && [ -n "$output" ]; then
    echo "PASS ($(echo "$output" | wc -l) buckets)"
    pass=$((pass + 1))
else
    echo "FAIL (got: $output)"
    fail=$((fail + 1))
fi

# TC-02: list folders at bucket root via CLI
echo -n "  [TC-02] List folders at bucket root (CLI auto) ... "
if output=$(python3 "$SCRIPT" --bucket "$BUCKET" --folders-only 2>&1) && [ -n "$output" ]; then
    echo "PASS ($(echo "$output" | wc -l) folders)"
    pass=$((pass + 1))
else
    echo "FAIL (got: $output)"
    fail=$((fail + 1))
fi

# TC-03: list sub-folders under prefix (CLI auto) — regression for BUG-002:
# must return the real sub-folder, NOT the prefix itself
echo -n "  [TC-03] List sub-folders under prefix (CLI auto) ... "
out=$(python3 "$SCRIPT" --bucket "$BUCKET" --prefix CloudTraces --folders-only 2>&1)
if [ -n "$out" ] && echo "$out" | grep -q "CloudTraces/cn-north-4/" && ! echo "$out" | grep -qE "^obs://$BUCKET/CloudTraces/$"; then
    echo "PASS"
    pass=$((pass + 1))
else
    echo "FAIL (got: $out)"
    fail=$((fail + 1))
fi

# TC-03b: prefix with trailing slash returns the same sub-folders
echo -n "  [TC-03b] Prefix with trailing slash ... "
out2=$(python3 "$SCRIPT" --bucket "$BUCKET" --prefix CloudTraces/ --folders-only 2>&1)
if [ -n "$out2" ] && echo "$out2" | grep -q "CloudTraces/cn-north-4/" && ! echo "$out2" | grep -qE "^obs://$BUCKET/CloudTraces/$"; then
    echo "PASS"
    pass=$((pass + 1))
else
    echo "FAIL (got: $out2)"
    fail=$((fail + 1))
fi

# TC-04: SDK executor — may be limited by env AK/SK permissions; must never
# crash with a raw exception (BUG-001 regression); accept clear Chinese error
echo -n "  [TC-04] List folders via SDK executor ... "
out=$(python3 "$SCRIPT" --bucket "$BUCKET" --folders-only --executor sdk 2>&1)
rc=$?
if [ "$rc" -eq 0 ] && [ -n "$out" ]; then
    echo "PASS"
    pass=$((pass + 1))
elif [ "$rc" -ne 0 ] && echo "$out" | grep -qE "AccessDenied|NoSuchBucket|InvalidAccessKeyId|未配置|错误"; then
    echo "PASS (env AK/SK permission-limited, clear error returned)"
    pass=$((pass + 1))
else
    echo "FAIL (exit=$rc: $out)"
    fail=$((fail + 1))
fi

# TC-05: nonexistent bucket error (auto)
run_exit_nonzero "TC-05" "Nonexistent bucket error (auto)" "NoSuchBucket" \
    "python3 '$SCRIPT' --bucket no-such-bucket-xyz --folders-only"

# TC-06: buckets via SDK — regression for BUG-001: must never crash with a
# raw exception; accept success (exit 0; possibly empty when the env AK/SK
# account owns no buckets) or a clear Chinese error
echo -n "  [TC-06] Buckets via SDK executor ... "
out=$(python3 "$SCRIPT" --buckets-only --executor sdk 2>&1)
rc=$?
if [ "$rc" -eq 0 ]; then
    if [ -n "$out" ]; then
        echo "PASS ($(echo "$out" | wc -l) buckets)"
    else
        echo "PASS (SDK authenticated; env AK/SK account owns 0 buckets)"
    fi
    pass=$((pass + 1))
elif echo "$out" | grep -qE "AccessDenied|NoSuchBucket|InvalidAccessKeyId|未配置|错误"; then
    echo "PASS (clear Chinese error returned, no raw crash)"
    pass=$((pass + 1))
else
    echo "FAIL (exit=$rc: $out)"
    fail=$((fail + 1))
fi

# TC-07: SDK availability check
run_test "TC-07" "SDK availability check" \
    "python3 -c \"from huaweicloudsdkobs.v1.obs_client import ObsClient; print('SDK OK')\""

# TC-08: quality SDK availability check
run_test "TC-08" "Quality SDK availability check" \
    "python3 -c \"import sys; sys.path.insert(0, '$SKILL_PATH/scripts'); from skill_quality_sdk import quality_report, QualityError; print('QUALITY SDK OK')\""

# TC-09: SDK ListBuckets response parsing (wrapper shape) — BUG-001 regression
echo -n "  [TC-09] SDK ListBuckets wrapper-shape parsing ... "
out=$(python3 -c "
import sys; sys.path.insert(0, '$SKILL_PATH/scripts')
import list_obs_folders as m
class R:
    def to_dict(self):
        return {'buckets': {'bucket': [{'name': 'a'}, {'name': 'b'}]}}
class C:
    def list_buckets(self, req):
        return R()
print(m.list_buckets_sdk(C()))
" 2>&1)
if [ "$out" = "['a', 'b']" ]; then
    echo "PASS"
    pass=$((pass + 1))
else
    echo "FAIL (got: $out)"
    fail=$((fail + 1))
fi

echo
echo "=== Results: $pass passed, $fail failed, $skip skipped ==="
[ "$fail" -eq 0 ]
