#!/usr/bin/env bash
set -euo pipefail

SKILL_PATH="${1:-.}"
EXECUTOR="${2:-cli}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SKILL_ROOT=$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)
VARS_FILE="${SKILL_ROOT}/templates/test-vars.json"

# Load defaults from templates/test-vars.json (if present). Env vars override JSON.
read_vars() {
  REGION=""
  CLUSTER_ID=""
  if [ -f "$VARS_FILE" ]; then
    REGION=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('region',''))" 2>/dev/null || true)
    CLUSTER_ID=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('cluster_id',''))" 2>/dev/null || true)
  fi
  REGION="${CCE_REGION:-${REGION:-cn-north-4}}"
  # Treat {placeholder} values in test-vars.json as unset (they are docs, not values).
  if [[ "$CLUSTER_ID" == \{*\} ]]; then CLUSTER_ID=""; fi
  CLUSTER_ID="${CCE_CLUSTER_ID:-$CLUSTER_ID}"
}

read_vars

echo "=== CCE Query Skill Test Script ==="
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

    # Response-body validation: hcloud exits 0 even when the CCE API returns an
    # error. Detect error markers so API failures are NOT masked as PASS.
    # A null "error_code" in a valid response is NOT an error.
    if grep -qE '\[USE_ERROR\]|"error_msg"|"error_code": *"[A-Za-z]' <<< "$output"; then
      if [ "$attempt" -lt "$max_attempts" ]; then
        # Transient failures (e.g. API calling timed out) get one retry.
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
    sed -n '1,5p' <<< "$output"
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
  run_test "TC-01" "List All CCE Clusters" \
    "hcloud CCE ListClusters --cli-region=$REGION"

  run_test "TC-02" "List CCE Clusters Filtered By Status" \
    "hcloud CCE ListClusters --cli-region=$REGION --status=Available"

  run_test "TC-03" "List CCE Clusters With Detail" \
    "hcloud CCE ListClusters --cli-region=$REGION --detail=true"

  run_test "TC-04" "Extract Cluster Names Only" \
    "hcloud CCE ListClusters --cli-region=$REGION | jq -r '.items[].metadata.name'"

  if [ -n "$CLUSTER_ID" ]; then
    run_test "TC-05" "Show Cluster Detail" \
      "hcloud CCE ShowCluster --cli-region=$REGION --cluster_id=$CLUSTER_ID"

    run_test "TC-06" "List Nodes Of Cluster" \
      "hcloud CCE ListNodes --cli-region=$REGION --cluster_id=$CLUSTER_ID"
  else
    echo "--- Skipping cluster-specific tests (set CCE_CLUSTER_ID or test-vars.json cluster_id to enable) ---"
    SKIP=$((SKIP + 2))
  fi
fi

if [ "$EXECUTOR" = "sdk" ]; then
  echo "=== SDK Mode Tests ==="
  set +e
  python3 -c "
import os, sys
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkcce.v3.region.cce_region import CceRegion
from huaweicloudsdkcce.v3 import CceClient, ListClustersRequest

ak = os.getenv('HUAWEI_ACCESS_KEY', '')
sk = os.getenv('HUAWEI_SECRET_KEY', '')
if not ak or not sk:
    print('SKIP: AK/SK not set in environment variables')
    sys.exit(2)

credentials = BasicCredentials().with_ak(ak).with_sk(sk)
client = CceClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(CceRegion.value_of('$REGION')) \
    .build()

req = ListClustersRequest()
resp = client.list_clusters(req)
items = resp.items if resp.items else []
names = [i.metadata.name for i in items]
print(f'PASS: ListClusters returned {len(items)} cluster(s): {names}')
" 2>&1
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
