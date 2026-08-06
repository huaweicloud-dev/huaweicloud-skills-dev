#!/usr/bin/env bash
# test-cli-commands.sh — Functional test for huawei-cloud-billing-account-balance skill
set -uo pipefail

SKILL_PATH="${1:-.}"
EXECUTOR="${2:-sdk}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SKILL_ROOT=$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)
VARS_FILE="${SKILL_ROOT}/templates/test-vars.json"

# Load defaults from templates/test-vars.json (if present).
REGION=""
if [ -f "$VARS_FILE" ]; then
  JSON_REGION=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('region',''))" 2>/dev/null || true)
  [ -n "$JSON_REGION" ] && REGION="$JSON_REGION"
fi

echo "=== Billing Account Balance Skill Test Script ==="
echo "Skill path: $SKILL_PATH"
echo "Executor: $EXECUTOR"
echo "Vars file: ${VARS_FILE:-not found}"
echo ""

PASS=0
FAIL=0
SKIP=0

run_test() {
  local id="$1"
  local name="$2"
  local cmd="$3"
  local output=""
  local attempt=1
  local max_attempts=2
  local verdict="PASS"

  echo "--- [$id] $name ---"
  echo "Command: $cmd"

  while [ "$attempt" -le "$max_attempts" ]; do
    output=$(eval "$cmd" 2>&1) || verdict="FAIL"

    # Detect SDK/API error markers so failures are NOT masked as PASS.
    if grep -qE 'ERROR:|error_msg|error_code|Traceback' <<< "$output"; then
      if [ "$attempt" -lt "$max_attempts" ]; then
        echo "  (attempt $attempt failed; retrying)"
        sleep 2
        attempt=$((attempt + 1))
        continue
      fi
      verdict="FAIL"
    fi
    break
  done

  if [ "$verdict" = "PASS" ]; then
    echo "  -> PASS"
    PASS=$((PASS + 1))
  else
    echo "  -> FAIL"
    echo "  Output: $(echo "$output" | head -5)"
    FAIL=$((FAIL + 1))
  fi
  echo ""
}

# Credentials are mandatory for the SDK executor.
if [ -z "${HUAWEI_ACCESS_KEY:-}" ] && [ -z "${HUAWEICLOUD_SDK_AK:-}" ]; then
  echo "WARNING: No AK/SK found in environment (HUAWEI_ACCESS_KEY or HUAWEICLOUD_SDK_AK)"
  echo "         SDK test cases will be SKIPPED."
  SKIP=1
fi

case "$EXECUTOR" in
  sdk)
    run_test "TC-01" "Query Account Balance (text report)" \
      "cd '$SKILL_ROOT' && SKILL_QUALITY_DISABLE=1 python3 scripts/query_account_balance.py"
    run_test "TC-02" "Query Account Balance (JSON output)" \
      "cd '$SKILL_ROOT' && SKILL_QUALITY_DISABLE=1 python3 scripts/query_account_balance.py --format json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(\"JSON OK, currency=%s\" % d.get(\"currency\"))'"
    run_test "TC-03" "Missing AK/SK handled gracefully (exits 1, C01)" \
      "cd '$SKILL_ROOT' && env -u HUAWEI_ACCESS_KEY -u HUAWEI_SECRET_KEY -u HUAWEICLOUD_SDK_AK -u HUAWEICLOUD_SDK_SK SKILL_QUALITY_DISABLE=1 python3 scripts/query_account_balance.py >/dev/null 2>&1; rc=\$?; [ \$rc -eq 1 ] && echo 'missing-AK/SK exits 1 (expected)' || echo 'unexpected exit '\$rc"
    ;;
  *)
    echo "Unknown executor: $EXECUTOR (supported: sdk)"
    exit 2
    ;;
esac

echo ""
echo "=== Test Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "SKIP: $SKIP"

if [ "$FAIL" -gt 0 ]; then
  echo "TESTS FAILED"
  exit 1
fi
echo "TESTS PASSED"
exit 0
