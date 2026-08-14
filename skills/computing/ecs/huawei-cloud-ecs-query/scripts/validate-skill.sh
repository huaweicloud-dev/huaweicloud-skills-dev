#!/bin/bash
# ECS Query Skill - Validation Script

SKILL_PATH="${1:-.}"

echo "=== Huawei Cloud Skill Validation ==="
echo "Skill path: $SKILL_PATH"
echo ""

ERRORS=0

check_file() {
    local file="$1"
    local level="$2"
    if [ -f "$file" ]; then
        echo "  [OK] $file exists"
    else
        echo "  [FAIL] $file missing ($level)"
        ERRORS=$((ERRORS + 1))
    fi
}

check_section() {
    local file="$1"
    local section="$2"
    local level="$3"
    if grep -q "$section" "$file" 2>/dev/null; then
        echo "  [OK] Section '$section' found"
    else
        echo "  [FAIL] Section '$section' missing ($level)"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "[1] File Structure"
check_file "$SKILL_PATH/SKILL.md" "Critical"
check_file "$SKILL_PATH/references/iam-policies.md" "Critical"
check_file "$SKILL_PATH/references/cli-installation-guide.md" "High"
check_file "$SKILL_PATH/references/verification-method.md" "Medium"
check_file "$SKILL_PATH/references/acceptance-criteria.md" "Low"
check_file "$SKILL_PATH/references/guide.md" "High"
check_file "$SKILL_PATH/templates/test-vars.json" "High"
check_file "$SKILL_PATH/scripts/check_env.sh" "High"

echo ""
echo "[2] SKILL.md Sections"
check_section "$SKILL_PATH/SKILL.md" "Overview" "High"
check_section "$SKILL_PATH/SKILL.md" "Prerequisites" "High"
check_section "$SKILL_PATH/SKILL.md" "Workflow" "High"
check_section "$SKILL_PATH/SKILL.md" "Core Commands" "High"
check_section "$SKILL_PATH/SKILL.md" "Parameter Confirmation" "High"
check_section "$SKILL_PATH/SKILL.md" "Reference Documents" "Critical"
check_section "$SKILL_PATH/SKILL.md" "KooCLI Command Format Standard" "Low"

echo ""
echo "[3] Frontmatter"
if grep -q "^name:" "$SKILL_PATH/SKILL.md"; then
    echo "  [OK] name field exists"
else
    echo "  [FAIL] name field missing"
    ERRORS=$((ERRORS + 1))
fi
if grep -q "^description:" "$SKILL_PATH/SKILL.md"; then
    echo "  [OK] description field exists"
else
    echo "  [FAIL] description field missing"
    ERRORS=$((ERRORS + 1))
fi
if grep -q "^version:" "$SKILL_PATH/SKILL.md"; then
    echo "  [FAIL] version field should not exist"
    ERRORS=$((ERRORS + 1))
else
    echo "  [OK] no version field"
fi

echo ""
echo "[4] Security"
if grep -rn "AK.*=" "$SKILL_PATH/scripts/" --include="*.py" 2>/dev/null | grep -v "os.getenv" | grep -v "getenv" | grep -v "environ" | grep -v "with_ak"; then
    echo "  [FAIL] Possible credential hardcoding detected"
    ERRORS=$((ERRORS + 1))
else
    echo "  [OK] No credential hardcoding detected"
fi

echo ""
echo "[5] File Count & Size"
FILE_COUNT=$(find "$SKILL_PATH" -type f | wc -l)
if [ "$FILE_COUNT" -le 30 ]; then
    echo "  [OK] File count: $FILE_COUNT (≤ 30)"
else
    echo "  [FAIL] File count: $FILE_COUNT (> 30)"
    ERRORS=$((ERRORS + 1))
fi

SKILL_LINES=$(wc -l < "$SKILL_PATH/SKILL.md")
if [ "$SKILL_LINES" -le 500 ]; then
    echo "  [OK] SKILL.md lines: $SKILL_LINES (≤ 500)"
else
    echo "  [FAIL] SKILL.md lines: $SKILL_LINES (> 500)"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "=== Validation Complete ==="
if [ "$ERRORS" -eq 0 ]; then
    echo "All checks passed!"
    exit 0
else
    echo "Errors found: $ERRORS"
    exit 1
fi
