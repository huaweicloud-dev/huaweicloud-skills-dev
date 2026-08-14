#!/usr/bin/env bash
# test-cli-commands.sh — Functional test for huawei-cloud-billing-bill-query skill
set -uo pipefail

SKILL_PATH="${1:-.}"
EXECUTOR="${2:-sdk}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SKILL_ROOT=$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)
VARS_FILE="${SKILL_ROOT}/templates/test-vars.json"

# Load defaults from templates/test-vars.json (if present).
if [ -f "$VARS_FILE" ]; then
  JSON_CYCLE=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('cycle',''))" 2>/dev/null || true)
  JSON_LIMIT=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('limit',''))" 2>/dev/null || true)
fi
CYCLE="${JSON_CYCLE:-$(date -d 'last month' +%Y-%m 2>/dev/null || date -v-1m +%Y-%m)}"
LIMIT="${JSON_LIMIT:-5}"

echo "=== Billing Bill Query Skill Test Script ==="
echo "Skill path: $SKILL_PATH"
echo "Executor: $EXECUTOR"
echo "Vars file: ${VARS_FILE:-not found}"
echo "Billing cycle: $CYCLE"
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
    run_test "TC-01" "Query Bill Fee Records (text)" \
      "cd '$SKILL_ROOT' && SKILL_QUALITY_DISABLE=1 python3 scripts/query_bills.py --action fee-records --bill-cycle $CYCLE --limit $LIMIT"
    run_test "TC-02" "Query Bill Fee Records (JSON)" \
      "cd '$SKILL_ROOT' && SKILL_QUALITY_DISABLE=1 python3 scripts/query_bills.py --action fee-records --bill-cycle $CYCLE --limit $LIMIT --format json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(\"JSON OK, action=%s, total=%s, currency=%s\" % (d.get(\"action\"), d.get(\"total_count\"), d.get(\"currency\")))'"
    run_test "TC-03" "Query Resource Fee Records (流水账单)" \
      "cd '$SKILL_ROOT' && SKILL_QUALITY_DISABLE=1 python3 scripts/query_bills.py --action res-fee-records --cycle $CYCLE --limit $LIMIT"
    run_test "TC-04" "Query Monthly Cost Breakdown" \
      "cd '$SKILL_ROOT' && SKILL_QUALITY_DISABLE=1 python3 scripts/query_bills.py --action breakdown --shared-month $CYCLE --limit $LIMIT"
    run_test "TC-05" "Invalid cycle format rejected" \
      "cd '$SKILL_ROOT' && SKILL_QUALITY_DISABLE=1 python3 scripts/query_bills.py --action fee-records --bill-cycle 2026/07 2>&1 | grep -q 'U02' && echo 'EXPECTED: U02 invalid format' || echo 'NOT REJECTED'"
    run_test "TC-06" "Missing AK/SK handled gracefully" \
      "cd '$SKILL_ROOT' && env -u HUAWEI_ACCESS_KEY -u HUAWEI_SECRET_KEY -u HUAWEICLOUD_SDK_AK -u HUAWEICLOUD_SDK_SK python3 scripts/query_bills.py --action fee-records --bill-cycle $CYCLE 2>&1 | grep -q 'C01' && echo 'EXPECTED: C01 missing AK/SK' || echo 'NOT REJECTED'"
    run_test "TC-07" "Cross-month date range rejected (BUG-1/N5)" \
      "cd '$SKILL_ROOT' && SKILL_QUALITY_DISABLE=1 python3 scripts/query_bills.py --action fee-records --bill-cycle $CYCLE --bill-date-begin 2026-06-20 --bill-date-end 2026-07-10 2>&1 | grep -q 'must fall within the billing cycle' && echo 'EXPECTED: U02 cross-month rejected' || echo 'NOT REJECTED'"
    run_test "TC-08" "limit out of range rejected (BUG-1/N6)" \
      "cd '$SKILL_ROOT' && SKILL_QUALITY_DISABLE=1 python3 scripts/query_bills.py --action fee-records --bill-cycle $CYCLE --limit 0 2>&1 | grep -q 'limit must be between 1 and 100' && echo 'EXPECTED: U02 limit rejected' || echo 'NOT REJECTED'"
    run_test "TC-09" "shared-month with fee-records rejected (BUG-2/N7)" \
      "cd '$SKILL_ROOT' && SKILL_QUALITY_DISABLE=1 python3 scripts/query_bills.py --action fee-records --shared-month $CYCLE 2>&1 | grep -q 'only valid with --action breakdown' && echo 'EXPECTED: U02 mismatch rejected' || echo 'NOT REJECTED'"
    run_test "TC-10" "bill-date with breakdown rejected (BUG-2/N8)" \
      "cd '$SKILL_ROOT' && SKILL_QUALITY_DISABLE=1 python3 scripts/query_bills.py --action breakdown --shared-month $CYCLE --bill-date-begin 2026-07-01 2>&1 | grep -q 'not supported by --action breakdown' && echo 'EXPECTED: U02 mismatch rejected' || echo 'NOT REJECTED'"
    ;;
  *)
    echo "Unknown executor: $EXECUTOR (only 'sdk' is supported for this skill)"
    exit 2
    ;;
esac

echo ""
echo "=== Test Summary ==="
echo "PASS: $PASS  FAIL: $FAIL  SKIP: $SKIP"
echo "===================="

[ "$FAIL" -eq 0 ]
