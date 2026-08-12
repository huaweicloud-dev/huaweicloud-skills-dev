#!/usr/bin/env bash
# test-cli-commands.sh — Functional test for huawei-cloud-vpc-list
# Usage:
#   bash test-cli-commands.sh {skill-path} --executor cli|sdk
# Default executor: cli

set -uo pipefail

SKILL_PATH="${1:-}"
EXECUTOR="cli"
if [[ "${2:-}" == "--executor" && -n "${3:-}" ]]; then
  EXECUTOR="$3"
fi

if [[ -z "$SKILL_PATH" || ! -d "$SKILL_PATH" ]]; then
  echo "[test] ERROR: valid skill path required"
  exit 1
fi

REGION="${REGION:-cn-north-4}"
LIMIT="${LIMIT:-3}"

pass=0
fail=0

run_case() {
  local name="$1"; shift
  echo ""
  echo "=================================================="
  echo "[test] $name"
  echo "  cmd: $*"
  echo "=================================================="
  if "$@" >/tmp/vpc_test_out.json 2>/tmp/vpc_test_err.txt; then
    echo "[test] PASS: command succeeded"
    pass=$((pass+1))
    return 0
  else
    echo "[test] FAIL: command failed"
    cat /tmp/vpc_test_err.txt
    fail=$((fail+1))
    return 1
  fi
}

echo "[test] Executor: ${EXECUTOR} | Region: ${REGION}"

if [[ "$EXECUTOR" == "cli" ]]; then
  # TC-01: List VPCs (v3, limited)
  run_case "TC-01 List VPCs (v3, limited)" hcloud VPC ListVpcs/v3 --cli-region="$REGION" --limit="$LIMIT" --cli-output=json

  # TC-02: List VPCs (v2 legacy)
  run_case "TC-02 List VPCs (v2 legacy)" hcloud VPC ListVpcs/v2 --cli-region="$REGION" --limit="$LIMIT" --cli-output=json

  # TC-03: Filter by name (v3)
  run_case "TC-03 Filter by name (v3)" hcloud VPC ListVpcs/v3 --cli-region="$REGION" --name.1=tf-web-vpc --cli-output=json

  # TC-04: Filter by enterprise project (all_granted_eps)
  run_case "TC-04 Filter by enterprise project (all_granted_eps)" hcloud VPC ListVpcs/v3 --cli-region="$REGION" --enterprise_project_id=all_granted_eps --limit="$LIMIT" --cli-output=json

  # TC-05: Max page size (limit=2000)
  run_case "TC-05 Max page size (limit=2000)" hcloud VPC ListVpcs/v3 --cli-region="$REGION" --limit=2000 --cli-output=json

  # TC-06: Pagination — verify accurate total via marker loop
  echo ""
  echo "=================================================="
  echo "[test] TC-06 Accurate total via marker pagination"
  echo "=================================================="
  total=0
  marker=""
  max_pages=10
  for ((i=1; i<=max_pages; i++)); do
    if [[ -z "$marker" ]]; then
      page_json=$(hcloud VPC ListVpcs/v3 --cli-region="$REGION" --limit=2000 --cli-output=json 2>/tmp/vpc_test_err.txt)
    else
      page_json=$(hcloud VPC ListVpcs/v3 --cli-region="$REGION" --limit=2000 --marker="$marker" --cli-output=json 2>/tmp/vpc_test_err.txt)
    fi
    if [[ -z "$page_json" ]]; then
      echo "[test] FAIL: empty response on page $i"
      cat /tmp/vpc_test_err.txt
      fail=$((fail+1))
      break
    fi
    count=$(echo "$page_json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('vpcs',[])))")
    total=$((total+count))
    next_marker=$(echo "$page_json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('page_info',{}).get('next_marker') or '')")
    echo "[test] page $i: records=$count accumulated=$total"
    if [[ -z "$next_marker" ]]; then
      break
    fi
    marker="$next_marker"
  done
  echo "[test] TC-06 accurate total VPCs: $total"
  pass=$((pass+1))
fi

if [[ "$EXECUTOR" == "sdk" ]]; then
  echo "[test] SDK fallback check: huaweicloudsdkvpc import"
  if python3 -c "from huaweicloudsdkvpc.v3 import ListVpcsRequest" 2>/tmp/vpc_test_err.txt; then
    echo "[test] PASS: SDK package available"
    pass=$((pass+1))
  else
    echo "[test] FAIL: SDK package missing"
    cat /tmp/vpc_test_err.txt
    fail=$((fail+1))
  fi
fi

echo ""
echo "==================== RESULT ===================="
echo "[test] PASS=$pass FAIL=$fail"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
exit 0
