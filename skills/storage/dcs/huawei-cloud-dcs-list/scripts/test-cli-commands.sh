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
  INSTANCE_ID=""
  if [ -f "$VARS_FILE" ]; then
    REGION=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('region',''))" 2>/dev/null || true)
    INSTANCE_ID=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('instance_id',''))" 2>/dev/null || true)
  fi
  REGION="${DCS_REGION:-${REGION:-cn-north-4}}"
  # Treat {placeholder} values in test-vars.json as unset (they are docs, not values).
  if [[ "$INSTANCE_ID" == \{*\} ]]; then INSTANCE_ID=""; fi
  INSTANCE_ID="${DCS_INSTANCE_ID:-$INSTANCE_ID}"
}

read_vars

echo "=== DCS List Skill Test Script ==="
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

    # Response-body validation: hcloud exits 0 even when the DCS API returns an
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
  run_test "TC-01" "List All DCS Instances" \
    "hcloud DCS ListInstances --cli-region=$REGION --limit=100"

  run_test "TC-02" "Extract DCS Instance Names Only" \
    "hcloud DCS ListInstances --cli-region=$REGION --limit=100 | jq -r '.instances[].name'"

  run_test "TC-03" "List DCS Instances Filtered By Name" \
    "hcloud DCS ListInstances --cli-region=$REGION --name=dcs-eval-client"

  run_test "TC-04" "List DCS Instances Filtered By Status" \
    "hcloud DCS ListInstances --cli-region=$REGION --status=RUNNING --limit=100"

  if [ -n "$INSTANCE_ID" ]; then
    run_test "TC-05" "Show DCS Instance Detail" \
      "hcloud DCS ShowInstance --cli-region=$REGION --instance_id=$INSTANCE_ID"
  else
    echo "--- Skipping instance-detail test (set DCS_INSTANCE_ID or test-vars.json instance_id to enable) ---"
    SKIP=$((SKIP + 1))
  fi
fi

if [ "$EXECUTOR" = "sdk" ]; then
  echo "=== SDK Mode Tests ==="
  set +e
  python3 -c "
import os, sys
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkdcs.v2.region.dcs_region import DcsRegion
from huaweicloudsdkdcs.v2 import dcs_client
from huaweicloudsdkdcs.v2.model import ListInstancesRequest

ak = os.getenv('HUAWEI_ACCESS_KEY', '')
sk = os.getenv('HUAWEI_SECRET_KEY', '')
if not ak or not sk:
    print('SKIP: AK/SK not set in environment variables')
    sys.exit(2)

credentials = BasicCredentials().with_ak(ak).with_sk(sk)
client = dcs_client.DcsClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(DcsRegion.value_of('$REGION')) \
    .build()

req = ListInstancesRequest()
req.limit = 100
resp = client.list_instances(req)
instances = resp.instances if resp.instances else []
names = [i.name for i in instances]
print(f'PASS: ListInstances returned {len(instances)} instance(s): {names}')
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
