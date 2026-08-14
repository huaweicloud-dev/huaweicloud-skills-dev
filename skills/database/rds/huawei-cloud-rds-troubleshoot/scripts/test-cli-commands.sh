#!/usr/bin/env bash
# test-cli-commands.sh — Functional test for huawei-cloud-rds-troubleshoot skill
set -uo pipefail

SKILL_PATH="${1:-.}"
EXECUTOR="${2:-cli}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
SKILL_ROOT=$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)
VARS_FILE="${SKILL_ROOT}/templates/test-vars.json"

# Load defaults from templates/test-vars.json (if present). Env vars override JSON.
REGION="cn-north-4"
INSTANCE_ID=""
if [ -f "$VARS_FILE" ]; then
  JSON_REGION=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('region',''))" 2>/dev/null || true)
  JSON_INSTANCE=$(python3 -c "import json;print(json.load(open('$VARS_FILE')).get('instance_id',''))" 2>/dev/null || true)
  [ -n "$JSON_REGION" ] && REGION="$JSON_REGION"
  [ -n "$JSON_INSTANCE" ] && INSTANCE_ID="$JSON_INSTANCE"
fi
REGION="${RDS_REGION:-$REGION}"
INSTANCE_ID="${RDS_INSTANCE_ID:-$INSTANCE_ID}"

# Time window for log queries: last 24h, UTC in the API-required
# "yyyy-mm-ddThh:mm:ss+0000" format (the RDS API rejects the 'Z' suffix)
START_TS=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S+0000 2>/dev/null || date -u -v-24H +%Y-%m-%dT%H:%M:%S+0000)
END_TS=$(date -u +%Y-%m-%dT%H:%M:%S+0000)

echo "=== RDS Troubleshoot Skill Test Script ==="
echo "Skill path: $SKILL_PATH"
echo "Executor: $EXECUTOR"
echo "Region: $REGION"
echo "Instance ID: ${INSTANCE_ID:-<auto-discover>}"
echo "Log window: $START_TS -> $END_TS"
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

    # Response-body validation: hcloud exits 0 even when the RDS API returns an
    # error. Detect error markers so API failures are NOT masked as PASS.
    # Matches both snake_case ("error_msg"/"error_code") and camelCase
    # ("errCode"/"externalMessage"/"errorMessage") error payloads, plus the
    # RDS DBS.NNNNN error-code pattern which appears in either form.
    if grep -qiE '\[USE_ERROR\]|"error_msg"|"error_code"|"errCode"|"externalMessage"|"errorMessage"|DBS\.[0-9]{5,}' <<< "$output"; then
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

# Auto-discover an instance ID when none is configured, and VALIDATE a
# configured ID before using it: a stale/hardcoded instance_id must not
# short-circuit discovery or cause instance-scoped tests to fail in an
# environment where that instance no longer exists. Instance-scoped tests
# are skipped when no real ACTIVE instance can be resolved.
instance_exists() {
  # returns 0 if $INSTANCE_ID resolves to a real instance (any status)
  local found
  found=$(hcloud RDS ListInstances --cli-region="$REGION" --id="$INSTANCE_ID" --cli-output=json 2>/dev/null \
    | python3 -c "import json,sys
try:
    d=json.load(sys.stdin)
    print('yes' if d.get('instances') else '')
except Exception:
    print('')")
  [ -n "$found" ]
}

auto_discover_instance() {
  # 1) A configured ID is only trusted if it really exists; otherwise discard it.
  if [ -n "$INSTANCE_ID" ]; then
    if instance_exists; then
      return 0
    fi
    echo "  (configured instance $INSTANCE_ID not found; re-discovering)"
    INSTANCE_ID=""
  fi
  # 2) Auto-discover the first ACTIVE instance in the region.
  INSTANCE_ID=$(hcloud RDS ListInstances --cli-region="$REGION" --cli-output=json 2>/dev/null \
    | python3 -c "import json,sys
try:
    d=json.load(sys.stdin)
    ids=[i['id'] for i in d.get('instances',[]) if i.get('status')=='ACTIVE']
    print(ids[0] if ids else '')
except Exception:
    print('')")
  [ -n "$INSTANCE_ID" ]
}

if [ "$EXECUTOR" = "cli" ]; then
  if ! command -v hcloud &>/dev/null; then
    echo "hcloud CLI not found. Falling back to SDK."
    EXECUTOR="sdk"
  fi
fi

if [ "$EXECUTOR" = "cli" ]; then
  run_test "TC-01" "List RDS Instances (inventory & status)" \
    "hcloud RDS ListInstances --cli-region=$REGION --cli-output=json"

  run_test "TC-02" "List Instances - MySQL engine filter" \
    "hcloud RDS ListInstances --cli-region=$REGION --datastore_type=MySQL --cli-output=json"

  run_test "TC-03" "Compact Instance Status Table" \
    "hcloud RDS ListInstances --cli-region=$REGION --cli-output=json | python3 -c \"import json,sys; d=json.load(sys.stdin); [print(i.get('name'), i.get('id'), i.get('status'), (i.get('datastore') or {}).get('type'), (i.get('volume') or {}).get('size')) for i in d.get('instances',[])]\""

  run_test "TC-04" "List Parameter Templates" \
    "hcloud RDS ListConfigurations --cli-region=$REGION --cli-output=json"

  run_test "TC-05" "Intelligent Diagnosis Summary (mysql)" \
    "hcloud RDS ListInstanceDiagnosis --cli-region=$REGION --engine=mysql --cli-output=json"

  run_test "TC-06" "Diagnosis Detail - high_pressure (mysql)" \
    "hcloud RDS ListInstancesInfoDiagnosis --cli-region=$REGION --engine=mysql --diagnosis=high_pressure --cli-output=json"

  if auto_discover_instance; then
    echo "--- Using instance: $INSTANCE_ID ---"
    echo ""

    run_test "TC-07" "Instance Detail (ListInstances --id)" \
      "hcloud RDS ListInstances --cli-region=$REGION --id=$INSTANCE_ID --cli-output=json"

    run_test "TC-08" "Replication / HA Status" \
      "hcloud RDS ShowReplicationStatus --cli-region=$REGION --instance_id=$INSTANCE_ID --cli-output=json"

    run_test "TC-09" "Storage Used Space" \
      "hcloud RDS ShowStorageUsedSpace --cli-region=$REGION --instance_id=$INSTANCE_ID --cli-output=json"

    run_test "TC-10" "Slow Logs (last 24h)" \
      "hcloud RDS ListSlowLogs --cli-region=$REGION --instance_id=$INSTANCE_ID --start_date=$START_TS --end_date=$END_TS --cli-output=json"

    run_test "TC-11" "Error Logs (last 24h)" \
      "hcloud RDS ListErrorLogsNew --cli-region=$REGION --instance_id=$INSTANCE_ID --start_date=$START_TS --end_date=$END_TS --cli-output=json"

    run_test "TC-12" "Instance Parameter Inspection" \
      "hcloud RDS ShowInstanceConfiguration --cli-region=$REGION --instance_id=$INSTANCE_ID --cli-output=json"

    run_test "TC-13" "Backup List" \
      "hcloud RDS ListBackups --cli-region=$REGION --instance_id=$INSTANCE_ID --cli-output=json"
  else
    echo "--- No ACTIVE instance found; skipping instance-scoped tests (TC-07..TC-13) ---"
    SKIP=$((SKIP + 7))
    echo ""
  fi
fi

if [ "$EXECUTOR" = "sdk" ]; then
  echo "=== SDK Mode Tests ==="
  set +e
  python3 -c "
import os, sys
try:
    from huaweicloudsdkcore.auth.credentials import BasicCredentials
    from huaweicloudsdkrds.v3.region.rds_region import RdsRegion
    from huaweicloudsdkrds.v3 import RdsClient, ListInstancesRequest
except ImportError:
    print('SKIP: huaweicloudsdkrds not installed')
    sys.exit(2)

ak = os.getenv('HUAWEI_ACCESS_KEY', '') or os.getenv('HUAWEICLOUD_SDK_AK', '')
sk = os.getenv('HUAWEI_SECRET_KEY', '') or os.getenv('HUAWEICLOUD_SDK_SK', '')
if not ak or not sk:
    print('SKIP: AK/SK not set in environment variables')
    sys.exit(2)

credentials = BasicCredentials().with_ak(ak).with_sk(sk)
client = RdsClient.new_builder() \
    .with_credentials(credentials) \
    .with_region(RdsRegion.value_of('$REGION')) \
    .build()

req = ListInstancesRequest()
resp = client.list_instances(req)
instances = resp.instances if resp.instances else []
print(f'PASS: ListInstances returned {len(instances)} instance(s)')
for i in instances[:5]:
    print(f'  - {i.name} {i.id} {i.status}')
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
