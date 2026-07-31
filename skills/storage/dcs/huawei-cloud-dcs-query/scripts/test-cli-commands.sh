#!/usr/bin/env bash
set -euo pipefail

SKILL_PATH="${1:-.}"
EXECUTOR="${2:-cli}"
REGION="${DCS_REGION:-cn-north-4}"

echo "=== DCS Query Skill Test Script ==="
echo "Skill path: $SKILL_PATH"
echo "Executor: $EXECUTOR"
echo "Region: $REGION"
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
  INSTANCE_ID="${DCS_INSTANCE_ID:-}"
  START_TIME="${DCS_START_TIME:-1598803200000}"
  END_TIME="${DCS_END_TIME:-1893455999000}"

  run_test "TC-01" "List DCS Instances" \
    "hcloud DCS ListInstances --cli-region=$REGION --limit=1"

  run_test "TC-02" "List Available Zones" \
    "hcloud DCS ListAvailableZones --cli-region=$REGION"

  run_test "TC-03" "List Maintenance Windows" \
    "hcloud DCS ListMaintenanceWindows --cli-region=$REGION"

  run_test "TC-04" "Show Tenant Quota" \
    "hcloud DCS ShowQuotaOfTenant --cli-region=$REGION"

  run_test "TC-05" "List Instances In Different Status" \
    "hcloud DCS ListNumberOfInstancesInDifferentStatus --cli-region=$REGION"

  run_test "TC-06" "List Running Instance Statistics" \
    "hcloud DCS ListStatisticsOfRunningInstances --cli-region=$REGION"

  run_test "TC-07" "List Migration Tasks" \
    "hcloud DCS ListMigrationTask --cli-region=$REGION --limit=1"

  if [ -n "$INSTANCE_ID" ]; then
    run_test "TC-08" "Show Instance" \
      "hcloud DCS ShowInstance --cli-region=$REGION --instance_id=$INSTANCE_ID"

    run_test "TC-09" "List Instance Configurations" \
      "hcloud DCS ListConfigurations --cli-region=$REGION --instance_id=$INSTANCE_ID"

    run_test "TC-10" "List Backup Records" \
      "hcloud DCS ListBackupRecords --cli-region=$REGION --instance_id=$INSTANCE_ID --limit=1"

    run_test "TC-11" "List Restore Records" \
      "hcloud DCS ListRestoreRecords --cli-region=$REGION --instance_id=$INSTANCE_ID --limit=1"

    run_test "TC-12" "List ACL Accounts" \
      "hcloud DCS ListAclAccounts --cli-region=$REGION --instance_id=$INSTANCE_ID"

    run_test "TC-13" "Show IP Whitelist" \
      "hcloud DCS ShowIpWhitelist --cli-region=$REGION --instance_id=$INSTANCE_ID"

    run_test "TC-14" "Show Instance Tags" \
      "hcloud DCS ShowTags --cli-region=$REGION --instance_id=$INSTANCE_ID"

    run_test "TC-15" "List Slow Logs" \
      "hcloud DCS ListSlowlog --cli-region=$REGION --instance_id=$INSTANCE_ID --start_time=$START_TIME --end_time=$END_TIME --limit=2"
  else
    echo "--- Skipping instance-specific tests (set DCS_INSTANCE_ID to enable) ---"
    SKIP=$((SKIP + 8))
  fi
fi

if [ "$EXECUTOR" = "sdk" ]; then
  echo "=== SDK Mode Tests ==="
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
    sys.exit(0)

credentials = BasicCredentials().with_ak(ak).with_sk(sk)
client = dcs_client.DcsClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(DcsRegion.value_of('$REGION')) \
    .build()

req = ListInstancesRequest()
req.limit = 1
resp = client.list_instances(req)
instances = resp.instances if resp.instances else []
print(f'PASS: ListInstances returned {len(instances)} instance(s)')
" 2>&1 && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
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
