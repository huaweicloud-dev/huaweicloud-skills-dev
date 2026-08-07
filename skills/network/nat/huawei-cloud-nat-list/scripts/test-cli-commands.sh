#!/usr/bin/env bash
# test-cli-commands.sh — Functional test for huawei-cloud-nat-list skill
set -uo pipefail

SKILL_PATH="${1:-.}"
EXECUTOR="${2:-cli}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SKILL_ROOT=$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)
VARS_FILE="${SKILL_ROOT}/templates/test-vars.json"

# Load defaults from templates/test-vars.json (if present). Env vars override JSON.
REGION="cn-north-4"
if [ -f "$VARS_FILE" ]; then
  JSON_REGION=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('region',''))" 2>/dev/null || true)
  [ -n "$JSON_REGION" ] && REGION="$JSON_REGION"
fi
REGION="${NAT_REGION:-$REGION}"

echo "=== NAT List Skill Test Script ==="
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

    # Response-body validation: hcloud exits 0 even when the NAT API returns an
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
  run_test "TC-01" "List All Public NAT Gateways" \
    "hcloud NAT ListNatGateways --cli-region=$REGION --cli-output=json"

  run_test "TC-02" "Extract NAT Gateway Names Only" \
    "hcloud NAT ListNatGateways --cli-region=$REGION --cli-query=\"nat_gateways[].name\""

  run_test "TC-03" "List NAT Gateways Filtered By Status" \
    "hcloud NAT ListNatGateways --cli-region=$REGION --status.1=ACTIVE --cli-output=json"

  run_test "TC-04" "List NAT Gateways Filtered By Spec" \
    "hcloud NAT ListNatGateways --cli-region=$REGION --spec.1=1 --cli-output=json"

  run_test "TC-05" "List NAT Gateways With Pagination" \
    "hcloud NAT ListNatGateways --cli-region=$REGION --limit=10 --cli-output=json"

  run_test "TC-06" "Quality-Reporting Wrapper (names only, reporting disabled)" \
    "SKILL_QUALITY_DISABLE=1 python3 $SKILL_ROOT/scripts/list_nat_gateways.py --region=$REGION --names-only"
fi

if [ "$EXECUTOR" = "sdk" ]; then
  echo "=== SDK Mode Tests ==="
  set +e
  python3 -c "
import os, sys
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdknat.v2.region.nat_region import NatRegion
from huaweicloudsdknat.v2 import NatClient, ListNatGatewaysRequest

ak = os.getenv('HUAWEI_ACCESS_KEY', '') or os.getenv('HUAWEICLOUD_SDK_AK', '')
sk = os.getenv('HUAWEI_SECRET_KEY', '') or os.getenv('HUAWEICLOUD_SDK_SK', '')
if not ak or not sk:
    print('SKIP: AK/SK not set in environment variables')
    sys.exit(2)

credentials = BasicCredentials().with_ak(ak).with_sk(sk)
client = NatClient.new_builder() \\
    .with_credentials(credentials) \\
    .with_region(NatRegion.value_of('$REGION')) \\
    .build()

req = ListNatGatewaysRequest(limit=25)
resp = client.list_nat_gateways(req)
gateways = resp.nat_gateways if resp.nat_gateways else []
names = [g.name for g in gateways]
print(f'PASS: ListNatGateways returned {len(gateways)} gateway(s): {names}')
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
