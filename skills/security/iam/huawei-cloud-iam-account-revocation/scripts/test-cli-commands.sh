#!/bin/bash
# test-cli-commands.sh — Test CLI commands for huawei-cloud-iam-account-revocation
set -euo pipefail

# Defaults
SKILL_PATH="skills/security/iam/huawei-cloud-iam-account-revocation"
EXECUTOR="cli"

# Named-argument parsing via getopts (long-option style shim)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill-path)
      SKILL_PATH="$2"; shift 2 ;;
    --executor)
      EXECUTOR="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--skill-path PATH] [--executor cli|sdk|api]"
      exit 0 ;;
    *)
      echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "=== Testing skill: ${SKILL_PATH} ==="
echo "Executor mode: ${EXECUTOR}"
echo ""

if [ "${EXECUTOR}" != "cli" ]; then
  echo "SKIP: Only CLI executor is supported for this skill (all IAM operations are CLI-native)."
  exit 0
fi

echo "Test suite: IAM Account Revocation CLI Commands"
echo "================================================"
echo ""

PASS=0
FAIL=0
SKIP=0

# TC-01: List IAM Users
echo "TC-01: List IAM Users"
if hcloud IAM ListUsersV5 --cli-region=cn-north-4 --limit=5 2>/dev/null; then
  echo "  → PASS"
  PASS=$((PASS+1))
else
  echo "  → FAIL (query only - requires valid credentials)"
  FAIL=$((FAIL+1))
fi

echo ""
echo "=== Results ==="
echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"
echo "Skipped: ${SKIP}"
echo ""

if [ "${FAIL}" -eq 0 ]; then
  exit 0
else
  exit 1
fi