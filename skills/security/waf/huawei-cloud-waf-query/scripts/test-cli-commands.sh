#!/usr/bin/env bash
# test-cli-commands.sh — Functional test runner for huawei-cloud-waf-query (CLI mode)
# Usage: bash scripts/test-cli-commands.sh <skill-dir> [--executor cli]
set -uo pipefail

SKILL_DIR="${1:-.}"
EXECUTOR="${2:-cli}"

echo "============================================"
echo "  WAF Query Skill — Functional Tests ($EXECUTOR)"
echo "============================================"

# Resolve credentials
: "${HUAWEICLOUD_SDK_AK:?Set HUAWEICLOUD_SDK_AK}"
: "${HUAWEICLOUD_SDK_SK:?Set HUAWEICLOUD_SDK_SK}"
REGION="${WAF_TEST_REGION:-cn-north-4}"
PROJECT_ID="${WAF_TEST_PROJECT_ID:-}"

if [ -z "$PROJECT_ID" ]; then
  PROJECT_ID=$(hcloud IAM KeystoneListProjects --cli-region="$REGION" --name="$REGION" 2>/dev/null | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['projects'][0]['id'])" 2>/dev/null || echo "")
fi
echo "region=$REGION project_id=${PROJECT_ID:0:8}..."
[ -z "$PROJECT_ID" ] && { echo "FAIL: cannot resolve project_id"; exit 1; }

FROM=$((($(date +%s%3N))-86400000))
TO=$(date +%s%3N)

run_case() {
  local id="$1" name="$2" cmd="$3"
  echo ""
  echo "--- $id: $name ---"
  local out rc
  out=$(timeout 60 bash -c "$cmd" 2>&1); rc=$?
  if [ $rc -ne 0 ]; then
    echo "  FAIL (exit=$rc): $(echo "$out" | head -3)"
    return 1
  fi
  echo "  PASS: $(echo "$out" | head -c 200)"
  return 0
}

PASS=0; FAIL=0

# TC-01 List attack events
run_case TC-01 "List attack events" \
  "hcloud WAF ListEvent --cli-region=$REGION --project_id=$PROJECT_ID --from=$FROM --to=$TO --pagesize=5" \
  && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

# TC-02 List attack events filtered by sqli
run_case TC-02 "List attack events (sqli filter)" \
  "hcloud WAF ListEvent --cli-region=$REGION --project_id=$PROJECT_ID --from=$FROM --to=$TO --attacks.1=sqli --pagesize=5" \
  && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

# TC-02b List attack events filtered by domain (array form; regression for --domain BUG-001)
run_case TC-02b "List attack events (domains.1 filter)" \
  "hcloud WAF ListEvent --cli-region=$REGION --project_id=$PROJECT_ID --from=$FROM --to=$TO --domains.1=test.example.com --pagesize=5" \
  && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

# TC-03 List access logs
run_case TC-03 "List access/protection logs" \
  "hcloud WAF ListEventLog --cli-region=$REGION --project_id=$PROJECT_ID --page=1 --pagesize=5" \
  && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

# TC-04 Attack statistics
run_case TC-04 "Attack statistics overview" \
  "hcloud WAF ListStatistics --cli-region=$REGION --project_id=$PROJECT_ID --from=$FROM --to=$TO" \
  && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

# TC-05 Threat overview
run_case TC-05 "Threat overview (today)" \
  "hcloud WAF ListThreats --cli-region=$REGION --project_id=$PROJECT_ID --from=$FROM --to=$TO --recent=today" \
  && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

# TC-06 Top IPs
run_case TC-06 "Top attack source IPs" \
  "hcloud WAF ListTopIp --cli-region=$REGION --project_id=$PROJECT_ID --from=$FROM --to=$TO" \
  && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

# TC-07 Invalid recent value
echo ""
echo "--- TC-07: Invalid recent value rejected ---"
out=$(timeout 60 hcloud WAF ListThreats --cli-region=$REGION --project_id=$PROJECT_ID --from=$FROM --to=$TO --recent=0 2>&1)
if echo "$out" | grep -q "USE_ERROR"; then
  echo "  PASS: USE_ERROR returned"
  PASS=$((PASS+1))
else
  echo "  FAIL: expected USE_ERROR, got: $(echo "$out" | head -2)"
  FAIL=$((FAIL+1))
fi

# TC-08 ShowEvent with non-existent eventid (regression for BUG-002)
run_case TC-08 "ShowEvent non-existent eventid" \
  "hcloud WAF ShowEvent --cli-region=$REGION --project_id=$PROJECT_ID --eventid=non-existent-event-id" \
  && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

echo ""
echo "============================================"
echo "  RESULT: $PASS passed, $FAIL failed"
echo "============================================"
[ $FAIL -eq 0 ]
