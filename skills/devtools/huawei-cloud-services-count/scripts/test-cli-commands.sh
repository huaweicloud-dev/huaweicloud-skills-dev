#!/usr/bin/env bash
# Test CLI commands for huawei-cloud-services-count skill
set -eo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

log_pass() { echo "[PASS] $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
log_fail() { echo "[FAIL] $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

echo "=== Testing huawei-cloud-services-count skill ==="

# Test 1: Check that services_en.json exists
echo "--- Test 1: Metadata file exists ---"
if [ -f "$HOME/.hcloud/metaRepo/services_en.json" ]; then
    log_pass "services_en.json exists"
else
    log_fail "services_en.json not found"
fi

# Test 2: Parse and count services
echo "--- Test 2: Count services ---"
COUNT=$(python3 -c "import json, os; data=json.load(open(os.path.expanduser('~/.hcloud/metaRepo/services_en.json'))); print(len(data.get('items',[])))" 2>/dev/null) || COUNT=0

if [ -n "$COUNT" ] && [ "$COUNT" -gt 100 ] 2>/dev/null; then
    log_pass "Service count: $COUNT (expected > 100)"
else
    log_fail "Service count: $COUNT (expected > 100)"
fi

# Test 3: hcloud meta download is available
echo "--- Test 3: hcloud meta command available ---"
if hcloud meta --help 2>&1 | grep -q "download"; then
    log_pass "hcloud meta download is available"
else
    log_fail "hcloud meta download not available"
fi

# Summary
echo ""
echo "=== Summary ===="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

[ "$TESTS_FAILED" -eq 0 ] || exit 1