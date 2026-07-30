#!/bin/bash
# ECS Query Skill - CLI Command Test Script

SKILL_DIR="${1:-.}"
EXECUTOR="${2:-cli}"

echo "=== ECS Query Skill Test Script ==="
echo "Skill directory: $SKILL_DIR"
echo "Executor mode: $EXECUTOR"
echo ""

PASS_COUNT=0
FAIL_COUNT=0

run_test() {
    local name="$1"
    local cmd="$2"
    echo "--- Testing: $name ---"
    if eval "$cmd" >/dev/null 2>&1; then
        echo "PASS"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "FAIL"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

if [ "$EXECUTOR" = "cli" ]; then
    run_test "ListServersDetails" "hcloud ECS ListServersDetails --cli-region=cn-north-4 --limit=1"
    run_test "ListFlavors" "hcloud ECS ListFlavors --cli-region=cn-north-4"
    run_test "ListServerGroups" "hcloud ECS ListServerGroups --cli-region=cn-north-4"
    run_test "NovaListKeypairs" "hcloud ECS NovaListKeypairs --cli-region=cn-north-4"
    run_test "ListServerTags" "hcloud ECS ListServerTags --cli-region=cn-north-4"
elif [ "$EXECUTOR" = "sdk" ]; then
    PYTHON="${SKILL_DIR}/.venv/bin/python3"
    run_test "list_servers_details" "$PYTHON ${SKILL_DIR}/scripts/ecs/list_servers_details.py --region=cn-north-4 --limit=1"
    run_test "list_flavors" "$PYTHON ${SKILL_DIR}/scripts/ecs/list_flavors.py --region=cn-north-4"
    run_test "list_server_groups" "$PYTHON ${SKILL_DIR}/scripts/ecs/list_server_groups.py --region=cn-north-4"
    run_test "nova_list_keypairs" "$PYTHON ${SKILL_DIR}/scripts/ecs/nova_list_keypairs.py --region=cn-north-4"
    run_test "list_server_tags" "$PYTHON ${SKILL_DIR}/scripts/ecs/list_server_tags.py --region=cn-north-4"
fi

echo ""
echo "=== Results ==="
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"
