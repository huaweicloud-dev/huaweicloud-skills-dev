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
  NAMESPACE=""
  if [ -f "$VARS_FILE" ]; then
    REGION=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('region',''))" 2>/dev/null || true)
    NAMESPACE=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('namespace',''))" 2>/dev/null || true)
  fi
  REGION="${SWR_REGION:-${REGION:-cn-north-4}}"
  NAMESPACE="${SWR_NAMESPACE:-${NAMESPACE:-}}"
}

read_vars

echo "=== SWR Namespace List Skill Test Script ==="
echo "Skill path: $SKILL_PATH"
echo "Executor: $EXECUTOR"
echo "Region: $REGION"
echo "Namespace: ${NAMESPACE:-<not set>}"
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

    # Response-body validation: hcloud exits 0 even when the SWR API returns an
    # error. Detect error markers so API failures are NOT masked as PASS.
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
  run_test "TC-01" "List All SWR Namespaces" \
    "hcloud SWR ListNamespaces --cli-region=$REGION"

  run_test "TC-02" "List Namespaces With JSON Output" \
    "hcloud SWR ListNamespaces --cli-region=$REGION --cli-output=json"

  if [ -n "$NAMESPACE" ] && [ "$NAMESPACE" != "{namespace}" ]; then
    run_test "TC-03" "List Namespaces Filtered By Name" \
      "hcloud SWR ListNamespaces --cli-region=$REGION --namespace=$NAMESPACE"
  else
    echo "--- [TC-03] List Namespaces Filtered By Name ---"
    echo "SKIP: namespace not set (set SWR_NAMESPACE env var or templates/test-vars.json)"
    SKIP=$((SKIP + 1))
    echo ""
  fi
fi

if [ "$EXECUTOR" = "sdk" ]; then
  echo "=== SDK Mode Tests ==="
  set +e
  python3 -c "
import os, sys
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkswr.v2.region.swr_region import SwrRegion
from huaweicloudsdkswr.v2 import swr_client
from huaweicloudsdkswr.v2.model import ListNamespacesRequest

ak = os.getenv('HUAWEI_ACCESS_KEY', '')
sk = os.getenv('HUAWEI_SECRET_KEY', '')
if not ak or not sk:
    print('SKIP: AK/SK not set in environment variables')
    sys.exit(2)

credentials = BasicCredentials().with_ak(ak).with_sk(sk)
client = swr_client.SwrClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(SwrRegion.value_of('$REGION')) \
    .build()

req = ListNamespacesRequest()
resp = client.list_namespaces(req)
namespaces = resp.namespaces if resp and resp.namespaces else []
names = [ns.name for ns in namespaces]
print(f'PASS: ListNamespaces returned {len(namespaces)} namespace(s): {names}')
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
