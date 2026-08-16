#!/usr/bin/env bash
# test-cli-commands.sh — Run the test cases defined in templates/test-vars.json
set -uo pipefail

SKILL_DIR="${1:-.}"
EXECUTOR="${2:-cli}"
VARS_FILE="$SKILL_DIR/templates/test-vars.json"

if [ ! -f "$VARS_FILE" ]; then
  echo "❌ test-vars.json not found: $VARS_FILE"
  exit 1
fi

PASS=0
FAIL=0

echo "============================================"
echo "  Running tests with executor: $EXECUTOR"
echo "============================================"

# Extract test cases (id/name/command/expected_exit) via python3 robust JSON parsing
# shellcheck disable=SC2016
CASES_JSON=$(python3 -c '
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for tc in data.get("test_cases", []):
    print(json.dumps({
        "id": tc.get("id", ""),
        "name": tc.get("name", ""),
        "command": tc.get("command", ""),
        "expected_exit": tc.get("expected_exit", 0),
    }))
' "$VARS_FILE")

while IFS= read -r case_json; do
  [ -n "$case_json" ] || continue
  TC_ID=$(printf '%s' "$case_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')
  TC_NAME=$(printf '%s' "$case_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["name"])')
  TC_CMD=$(printf '%s' "$case_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["command"])')
  TC_EXPECTED=$(printf '%s' "$case_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["expected_exit"])')

  echo ""
  echo "▶ [$TC_ID] $TC_NAME"
  echo "  cmd: $TC_CMD"
  # Run from the skill directory so relative paths like scripts/ work
  (cd "$SKILL_DIR" && eval "$TC_CMD") > /tmp/skill_test_out.log 2>&1
  ACTUAL=$?
  if [ "$ACTUAL" -eq "$TC_EXPECTED" ]; then
    echo "  ✅ PASS (exit $ACTUAL, expected $TC_EXPECTED)"
    PASS=$((PASS + 1))
  else
    echo "  ❌ FAIL (exit $ACTUAL, expected $TC_EXPECTED)"
    echo "  --- output ---"
    sed 's/^/  /' /tmp/skill_test_out.log | head -20
    FAIL=$((FAIL + 1))
  fi
done <<< "$CASES_JSON"

echo ""
echo "============================================"
echo "  Result: PASS=$PASS FAIL=$FAIL"
echo "============================================"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
