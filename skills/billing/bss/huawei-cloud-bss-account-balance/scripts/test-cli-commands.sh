#!/usr/bin/env bash
# test-cli-commands.sh — Functional test runner for huawei-cloud-bss-account-balance.
# Executes SDK test cases from templates/test-vars.json against the live BSS API.
# Usage: bash scripts/test-cli-commands.sh {skill-path} [--executor sdk]
set -uo pipefail

SKILL_DIR="${1:-.}"
EXECUTOR="sdk"
if [ "${2:-}" = "--executor" ] && [ -n "${3:-}" ]; then
  EXECUTOR="$3"
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_VARS="$SKILL_DIR/templates/test-vars.json"

echo "============================================"
echo "  Testing huawei-cloud-bss-account-balance"
echo "  Executor: $EXECUTOR"
echo "============================================"

if [ ! -f "$TEST_VARS" ]; then
  echo "❌ FAIL: $TEST_VARS not found"
  exit 1
fi

PASS=0
FAIL=0
TOTAL=$(python3 -c "import json;print(len(json.load(open('$TEST_VARS'))['test_cases']))")

for i in $(seq 0 $((TOTAL - 1))); do
  TC_ID=$(python3 -c "import json;d=json.load(open('$TEST_VARS'));print(d['test_cases'][$i]['id'])")
  TC_CMD=$(python3 -c "import json;d=json.load(open('$TEST_VARS'));print(d['test_cases'][$i]['command'])")
  TC_NAME=$(python3 -c "import json;d=json.load(open('$TEST_VARS'));print(d['test_cases'][$i]['name'])")
  echo ""
  echo "--- $TC_ID: $TC_NAME ---"
  if eval "$TC_CMD" > /tmp/bss_test_out.json 2>/tmp/bss_test_err.txt; then
    echo "  ✅ PASS: command executed successfully"
    # Negative cases (containing 'test $?') produce no JSON — skip summary parse
    if echo "$TC_CMD" | grep -q 'test $?'; then
      echo "  (negative case: expected non-zero exit verified)"
    else
      python3 -c "import json;d=json.load(open('/tmp/bss_test_out.json'));print('  balance:', json.dumps(d.get('balance',{}),ensure_ascii=False)[:200]);print('  records total:', d.get('change_records',{}).get('total_count'))"
    fi
    PASS=$((PASS + 1))
  else
    echo "  ❌ FAIL: command failed"
    tail -5 /tmp/bss_test_err.txt | sed 's/^/    /'
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "============================================"
echo "  Result: PASS=$PASS FAIL=$FAIL TOTAL=$TOTAL"
echo "============================================"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
