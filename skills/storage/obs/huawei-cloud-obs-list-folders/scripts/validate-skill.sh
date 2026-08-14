#!/usr/bin/env bash
# validate-skill.sh — Huawei Cloud Skill Specification validation
set -euo pipefail

SKILL_PATH="${1:?Usage: validate-skill.sh <skill-path>}"

echo "=== Huawei Cloud Skill Validation ==="
echo "Skill path: $SKILL_PATH"
echo ""

CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0
PASS=0

check() {
  local level="$1"
  local name="$2"
  local result="$3"
  if [ "$result" = "PASS" ]; then
    echo "  [PASS] [$level] $name"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] [$level] $name"
    case "$level" in
      Critical) CRITICAL=$((CRITICAL + 1)) ;;
      High) HIGH=$((HIGH + 1)) ;;
      Medium) MEDIUM=$((MEDIUM + 1)) ;;
      Low) LOW=$((LOW + 1)) ;;
    esac
  fi
}

SKILL_MD="$SKILL_PATH/SKILL.md"

# Critical checks
check "Critical" "SKILL.md exists" "$([ -f "$SKILL_MD" ] && echo PASS || echo FAIL)"
check "Critical" "YAML frontmatter exists" "$(head -1 "$SKILL_MD" 2>/dev/null | grep -q '^---$' && echo PASS || echo FAIL)"
check "Critical" "name field exists" "$(grep -q '^name:' "$SKILL_MD" && echo PASS || echo FAIL)"
check "Critical" "description field exists" "$(grep -q '^description:' "$SKILL_MD" && echo PASS || echo FAIL)"
check "Critical" "Reference Documents section" "$(grep -qi 'Reference Documents\|References\|参考文档' "$SKILL_MD" && echo PASS || echo FAIL)"
check "Critical" "references/iam-policies.md exists" "$([ -f "$SKILL_PATH/references/iam-policies.md" ] && echo PASS || echo FAIL)"
check "Critical" "No credential hardcoding" "$(grep -qiE '(AK=|SK=|access.key=|secret.key=|password=)' "$SKILL_MD" && echo FAIL || echo PASS)"

# High checks
check "High" "Overview section" "$(grep -qi 'Overview\|概述' "$SKILL_MD" && echo PASS || echo FAIL)"
check "High" "Prerequisites section" "$(grep -qi 'Prerequisites\|前置条件' "$SKILL_MD" && echo PASS || echo FAIL)"
check "High" "Workflow section" "$(grep -qi 'Workflow\|工作流' "$SKILL_MD" && echo PASS || echo FAIL)"
check "High" "Core Commands section" "$(grep -qi 'Core Commands\|核心命令' "$SKILL_MD" && echo PASS || echo FAIL)"
check "High" "Parameter Confirmation section" "$(grep -qi 'Parameter Confirmation\|参数确认' "$SKILL_MD" && echo PASS || echo FAIL)"
check "High" "CLI installation guide" "$([ -f "$SKILL_PATH/references/cli-installation-guide.md" ] && echo PASS || echo FAIL)"

# Medium checks
check "Medium" "description includes trigger words" "$(grep -qi 'trigger\|use when' "$SKILL_MD" && echo PASS || echo FAIL)"
check "Medium" "No version field" "$(grep -q '^version:' "$SKILL_MD" && echo FAIL || echo PASS)"
check "Medium" "verification-method.md exists" "$([ -f "$SKILL_PATH/references/verification-method.md" ] && echo PASS || echo FAIL)"
check "Medium" "Service name OBS uppercase" "$(grep -q 'hcloud OBS' "$SKILL_MD" && echo PASS || echo FAIL)"
check "Medium" "Includes hcloud OBS ls command" "$(grep -q 'hcloud OBS ls' "$SKILL_MD" && echo PASS || echo FAIL)"

# Low checks
check "Low" "acceptance-criteria.md exists" "$([ -f "$SKILL_PATH/references/acceptance-criteria.md" ] && echo PASS || echo FAIL)"
check "Low" "dataflow-diagram.md exists" "$([ -f "$SKILL_PATH/references/dataflow-diagram.md" ] && echo PASS || echo FAIL)"
check "Low" "Reference filenames kebab-case" "$(find "$SKILL_PATH/references" -type f ! -name '*-*.md' ! -name '*.md' 2>/dev/null | grep -q . && echo FAIL || echo PASS)"
check "Low" "KooCLI Command Format Standard section" "$(grep -qi 'KooCLI Command Format' "$SKILL_MD" && echo PASS || echo FAIL)"

# Package limits
FILE_COUNT=$(find "$SKILL_PATH" -type f | wc -l)
LINE_COUNT=$(wc -l < "$SKILL_MD")
SIZE_KB=$(du -sk "$SKILL_PATH" | cut -f1)
check "Medium" "Total files <= 30 (got $FILE_COUNT)" "$([ "$FILE_COUNT" -le 30 ] && echo PASS || echo FAIL)"
check "Medium" "SKILL.md <= 500 lines (got $LINE_COUNT)" "$([ "$LINE_COUNT" -le 500 ] && echo PASS || echo FAIL)"
check "Medium" "Total size <= 40MB (got ${SIZE_KB}KB)" "$([ "$SIZE_KB" -le 40960 ] && echo PASS || echo FAIL)"

# Script syntax checks
check "Medium" "list_obs_folders.py compiles" "$(python3 -m py_compile "$SKILL_PATH/scripts/list_obs_folders.py" 2>/dev/null && echo PASS || echo FAIL)"
check "Medium" "test-cli-commands.sh syntax" "$(bash -n "$SKILL_PATH/scripts/test-cli-commands.sh" 2>/dev/null && echo PASS || echo FAIL)"

echo ""
echo "=== Summary: $PASS passed; Critical=$CRITICAL High=$HIGH Medium=$MEDIUM Low=$LOW ==="
[ "$CRITICAL" -eq 0 ] && [ "$HIGH" -eq 0 ]
