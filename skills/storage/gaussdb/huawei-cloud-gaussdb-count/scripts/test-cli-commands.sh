#!/usr/bin/env bash
# test-cli-commands.sh — Functional tests for the huawei-cloud-gaussdb-count skill.
#
# Usage:
#   bash scripts/test-cli-commands.sh {skill-path} --executor cli   # CLI primary
#   bash scripts/test-cli-commands.sh {skill-path} --executor sdk   # SDK fallback
set -euo pipefail

SKILL_PATH="${1:-.}"
EXECUTOR="${2:-cli}"
if [ "$SKILL_PATH" = "--executor" ]; then
  SKILL_PATH="."
  EXECUTOR="${3:-cli}"
elif [ "$2" = "--executor" ]; then
  EXECUTOR="${3:-cli}"
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SKILL_ROOT=$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)
VARS_FILE="${SKILL_ROOT}/templates/test-vars.json"

read_vars() {
  REGION=""
  if [ -f "$VARS_FILE" ]; then
    REGION=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('region',''))" 2>/dev/null || true)
  fi
  REGION="${GAUSSDB_REGION:-${REGION:-cn-north-4}}"
}

read_vars

echo "=== GaussDB Count Skill Test Script ==="
echo "Skill path: $SKILL_PATH"
echo "Executor: $EXECUTOR"
echo "Region: $REGION"
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

    # Detect error markers so API failures are NOT masked as PASS.
    if grep -qE '\[USE_ERROR\]|"error_msg"|"error_code": *"[A-Za-z]' <<< "$output"; then
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
    echo "Result: PASS"
    sed -n '1,10p' <<< "$output"
    PASS=$((PASS + 1))
  else
    echo "Result: FAIL"
    sed -n '1,10p' <<< "$output"
    FAIL=$((FAIL + 1))
  fi
  echo ""
}

if [ "$EXECUTOR" = "cli" ]; then
  if ! command -v hcloud &>/dev/null; then
    echo "hcloud CLI not found. Falling back to SDK."
    EXECUTOR="sdk"
  fi
fi

if [ "$EXECUTOR" = "cli" ]; then
  run_test "TC-01" "Count GaussDB for openGauss instances" \
    "hcloud GaussDBforopenGauss ListInstances --cli-region=$REGION --limit=100"

  run_test "TC-02" "Extract GaussDB for openGauss count only" \
    "hcloud GaussDBforopenGauss ListInstances --cli-region=$REGION --limit=100 | jq -r '.total_count'"

  run_test "TC-03" "Sum GaussDB for openGauss storage size (GB)" \
    "hcloud GaussDBforopenGauss ListInstances --cli-region=$REGION --limit=100 | jq '[.instances[].volume.size // 0 | tonumber] | add // 0'"

  run_test "TC-04" "Count GaussDB (MySQL) instances" \
    "hcloud GaussDB ListGaussMySqlInstances --cli-region=$REGION --limit=100"

  run_test "TC-05" "Extract GaussDB (MySQL) count only" \
    "hcloud GaussDB ListGaussMySqlInstances --cli-region=$REGION --limit=100 | jq -r '.total_count'"

  run_test "TC-06" "Sum GaussDB (MySQL) storage size (GB)" \
    "hcloud GaussDB ListGaussMySqlInstances --cli-region=$REGION --limit=100 | jq '[.instances[].volume.size // 0 | tonumber] | add // 0'"
fi

if [ "$EXECUTOR" = "sdk" ]; then
  echo "=== SDK Mode Tests ==="
  set +e
  python3 "$SKILL_ROOT/scripts/count_gaussdb_instances.py" --region "$REGION" --limit 100 2>&1
  SDK_EXIT=$?
  set -e
  if [ "$SDK_EXIT" -eq 0 ]; then
    PASS=$((PASS + 1))
  elif [ "$SDK_EXIT" -eq 2 ]; then
    SKIP=$((SKIP + 1))
  else
    FAIL=$((FAIL + 1))
  fi
fi

echo ""
echo "=== Test Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "SKIP: $SKIP"
echo "Total: $((PASS + FAIL + SKIP))"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
