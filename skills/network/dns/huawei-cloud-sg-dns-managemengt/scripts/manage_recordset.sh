#!/bin/bash
# manage_recordset.sh - 创建 / 更新 / 删除 DNS Record Set
# 基于 hcloud CLI（KooCLI）
#
# Usage:
#   bash manage_recordset.sh --action create --zone-name example.com. --name www.example.com. --type A --records "192.168.1.100"
#   bash manage_recordset.sh --action update --zone-name example.com. --name www.example.com. --type A --records "192.168.2.200"
#   bash manage_recordset.sh --action delete --zone-name example.com. --name old.example.com. --type A
#   bash manage_recordset.sh --action create --zone-name example.com. --name app.example.com. --type A --records "192.168.1.100 192.168.1.101" --ttl 300

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# ── 参数解析 ──────────────────────────────────────────────────────
ACTION=""
ZONE_NAME=""
ZONE_TYPE="public"
RECORD_NAME=""
RECORD_TYPE=""
RECORDS=""
TTL="300"

while [[ $# -gt 0 ]]; do
    case $1 in
        --action)    ACTION="$2"; shift 2 ;;
        --zone-name) ZONE_NAME="$2"; shift 2 ;;
        --zone-type) ZONE_TYPE="$2"; shift 2 ;;
        --name)      RECORD_NAME="$2"; shift 2 ;;
        --type)      RECORD_TYPE="$2"; shift 2 ;;
        --records)   RECORDS="$2"; shift 2 ;;
        --ttl)       TTL="$2"; shift 2 ;;
        --help|-h)
            echo "用法: $0 --action <create|update|delete> --zone-name <FQDN> --name <FQDN> --type <TYPE> [选项]"
            echo ""
            echo "必需参数："
            echo "  --action      操作类型：create / update / delete"
            echo "  --zone-name   Zone 名称（FQDN，含末尾点，如 example.com.）"
            echo "  --name        Record Set 名称（FQDN，含末尾点，如 www.example.com.）"
            echo "  --type        记录类型：A / AAAA / CNAME / MX / TXT / NS / SRV / CAA"
            echo ""
            echo "可选参数："
            echo "  --zone-type   Zone 类型：public / private（默认：public）"
            echo "  --records     记录值（空格分隔，create/update 必需）"
            echo "  --ttl         TTL 秒数（默认：300）"
            echo ""
            echo "示例："
            echo "  $0 --action create --zone-name example.com. --name www.example.com. --type A --records \"192.168.1.100\""
            echo "  $0 --action update --zone-name example.com. --name www.example.com. --type A --records \"192.168.2.200\" --ttl 600"
            echo "  $0 --action delete --zone-name example.com. --name old.example.com. --type A --zone-type private"
            exit 0 ;;
        *) echo "未知选项: $1" >&2; exit 1 ;;
    esac
done

# ── 校验必需参数 ──────────────────────────────────────────────────
if [ -z "$ACTION" ]; then
    color_print "$RED" "❌ 缺少必需参数: --action"
    echo "使用 --help 查看用法" >&2
    exit 1
fi

case "$ACTION" in
    create|update|delete) ;;
    *)
        color_print "$RED" "❌ 不支持的操作: '$ACTION'（仅支持 create / update / delete）" >&2
        exit 1
        ;;
esac

if [ -z "$ZONE_NAME" ]; then
    color_print "$RED" "❌ 缺少必需参数: --zone-name" >&2; exit 1
fi

if [ -z "$RECORD_NAME" ]; then
    color_print "$RED" "❌ 缺少必需参数: --name" >&2; exit 1
fi

if [ -z "$RECORD_TYPE" ]; then
    color_print "$RED" "❌ 缺少必需参数: --type" >&2; exit 1
fi

# 校验记录类型
case "$RECORD_TYPE" in
    A|AAAA|CNAME|MX|TXT|NS|SRV|CAA) ;;
    *)
        color_print "$RED" "❌ 不支持的记录类型: '$RECORD_TYPE'" >&2
        echo "支持的类型: A, AAAA, CNAME, MX, TXT, NS, SRV, CAA" >&2
        exit 1
        ;;
esac

case "$ZONE_TYPE" in
    public|private) ;;
    *) color_print "$RED" "❌ 不支持的 zone 类型: '$ZONE_TYPE'（仅支持 public / private）" >&2; exit 1 ;;
esac

# create/update 需要 --records
if [ "$ACTION" = "create" ] || [ "$ACTION" = "update" ]; then
    if [ -z "$RECORDS" ]; then
        color_print "$RED" "❌ 操作 ${ACTION} 需要参数: --records" >&2
        exit 1
    fi
fi

# ── 审计日志 ──────────────────────────────────────────────────────
AUDIT_LOG_DIR="${SCRIPT_DIR}/../dns_audit_logs"
mkdir -p "$AUDIT_LOG_DIR" 2>/dev/null || true
AUDIT_LOG="${AUDIT_LOG_DIR}/audit_$(date '+%Y%m%d').jsonl"

get_timestamp() {
    local tz_offset
    tz_offset=$(date +%z 2>/dev/null || echo "+0000")
    date "+%Y-%m-%dT%H:%M:%S${tz_offset:0:3}:${tz_offset:3:2}"
}

log_audit() {
    local action="$1"
    local detail="$2"
    local result="$3"
    local timestamp
    timestamp=$(get_timestamp)

    local entry
    entry=$(jq -n -c \
        --arg timestamp "$timestamp" \
        --arg region "$HW_REGION" \
        --arg action "$action" \
        --arg detail "$detail" \
        --arg result "$result" \
        --arg user "$(whoami 2>/dev/null || echo 'unknown')" \
        '{
            timestamp: $timestamp,
            region: $region,
            action: $action,
            detail: $detail,
            result: $result,
            user: $user
        }')

    echo "$entry" >> "$AUDIT_LOG" 2>/dev/null || true
}

# ── 查找 Zone ID ──────────────────────────────────────────────────
find_zone_id() {
    local target_name="$1"
    local target_type="$2"
    local raw_json zones_json

    if [ "$target_type" = "public" ]; then
        raw_json=$(run_hcloud DNS ListPublicZones --limit=1000 2>/dev/null) || {
            color_print "$RED" "❌ 查询公网 Zone 列表失败"
            return 1
        }
    else
        raw_json=$(run_hcloud DNS ListPrivateZones --limit=1000 2>/dev/null) || {
            color_print "$RED" "❌ 查询私网 Zone 列表失败"
            return 1
        }
    fi

    zones_json=$(echo "$raw_json" | jq -c '.zones // []')

    local zone_id
    zone_id=$(echo "$zones_json" | jq -r --arg name "$target_name" '.[] | select(.name == $name) | .id' | head -1)

    if [ -z "$zone_id" ] || [ "$zone_id" = "null" ]; then
        color_print "$RED" "❌ 未找到 Zone: ${target_name}（类型: ${target_type}）"
        echo "请检查 Zone 名称是否正确（需包含末尾点，如 example.com.）" >&2
        return 1
    fi

    echo "$zone_id"
}

# ── 查找 Record Set ID（用于 update/delete）──────────────────────
find_recordset_id() {
    local zone_id="$1"
    local target_name="$2"
    local target_type="$3"
    local ztype="$4"
    local raw_json

    if [ "$ztype" = "public" ]; then
        raw_json=$(run_hcloud DNS ListRecordSets --zone_id="$zone_id" --limit=1000 2>/dev/null) || {
            return 1
        }
    else
        raw_json=$(run_hcloud DNS ListPrivateRecordSets --zone_id="$zone_id" --limit=1000 2>/dev/null) || {
            return 1
        }
    fi

    local rs_id
    rs_id=$(echo "$raw_json" | jq -r --arg name "$target_name" --arg type "$target_type" \
        '.recordsets[] | select(.name == $name and .type == $type) | .id' | head -1)

    if [ -z "$rs_id" ] || [ "$rs_id" = "null" ]; then
        echo ""
    else
        echo "$rs_id"
    fi
}

# ── 将空格分隔的记录值转为 JSON 数组 ──────────────────────────────
records_to_json() {
    local records_str="$1"
    # 将空格分隔的值转为 jq JSON 数组
    echo "$records_str" | tr ' ' '\n' | jq -R -c '[.[] | select(length > 0)] | map(gsub("^\"|\"$"; "\""))'
}

# ── 主逻辑 ────────────────────────────────────────────────────────
main() {
    # 查找 Zone ID
    color_print "$CYAN" "🔍 查找 Zone: ${ZONE_NAME}（类型: ${ZONE_TYPE}）..."

    local zone_id
    zone_id=$(find_zone_id "$ZONE_NAME" "$ZONE_TYPE") || exit 1

    color_print "$GREEN" "✅ 找到 Zone ID: ${zone_id}"
    echo ""

    # ── 创建 Record Set ────────────────────────────────────────────
    if [ "$ACTION" = "create" ]; then
        color_print "$CYAN" "📝 创建 Record Set: ${RECORD_NAME} (${RECORD_TYPE})..."

        # 检查是否已存在
        local existing_id
        existing_id=$(find_recordset_id "$zone_id" "$RECORD_NAME" "$RECORD_TYPE" "$ZONE_TYPE")
        if [ -n "$existing_id" ]; then
            color_print "$YELLOW" "⚠️  Record Set 已存在 (ID: ${existing_id})，请使用 --action update 进行更新"
            log_audit "create" "Zone=${ZONE_NAME}, Name=${RECORD_NAME}, Type=${RECORD_TYPE}, Records=${RECORDS}" "skipped_already_exists"
            exit 1
        fi

        # 构造 records JSON 数组
        local records_json
        records_json=$(records_to_json "$RECORDS")

        local raw_json
        if [ "$ZONE_TYPE" = "public" ]; then
            raw_json=$(run_hcloud DNS CreateRecordSet \
                --zone_id="$zone_id" \
                --name="$RECORD_NAME" \
                --type="$RECORD_TYPE" \
                --records="$records_json" \
                --ttl="$TTL" 2>&1) || {
                color_print "$RED" "❌ 创建 Record Set 失败"
                echo "$raw_json" >&2
                log_audit "create" "Zone=${ZONE_NAME}, Name=${RECORD_NAME}, Type=${RECORD_TYPE}, Records=${RECORDS}" "failed"
                exit 1
            }
        else
            raw_json=$(run_hcloud DNS CreatePrivateRecordSet \
                --zone_id="$zone_id" \
                --name="$RECORD_NAME" \
                --type="$RECORD_TYPE" \
                --records="$records_json" \
                --ttl="$TTL" 2>&1) || {
                color_print "$RED" "❌ 创建私网 Record Set 失败"
                echo "$raw_json" >&2
                log_audit "create" "Zone=${ZONE_NAME}, Name=${RECORD_NAME}, Type=${RECORD_TYPE}, Records=${RECORDS}" "failed"
                exit 1
            }
        fi

        local new_id
        new_id=$(echo "$raw_json" | jq -r '.id // "N/A"' 2>/dev/null || echo "N/A")

        color_print "$GREEN" "✅ Record Set 创建成功！"
        echo "  Zone:        ${ZONE_NAME} (${ZONE_TYPE})"
        echo "  名称:        ${RECORD_NAME}"
        echo "  类型:        ${RECORD_TYPE}"
        echo "  记录值:      ${RECORDS}"
        echo "  TTL:         ${TTL}"
        echo "  Record Set ID: ${new_id}"

        log_audit "create" "Zone=${ZONE_NAME}, Name=${RECORD_NAME}, Type=${RECORD_TYPE}, Records=${RECORDS}, TTL=${TTL}, ID=${new_id}" "success"
        exit 0
    fi

    # ── 更新 Record Set ────────────────────────────────────────────
    if [ "$ACTION" = "update" ]; then
        color_print "$CYAN" "📝 更新 Record Set: ${RECORD_NAME} (${RECORD_TYPE})..."

        # 查找现有 Record Set ID
        local rs_id
        rs_id=$(find_recordset_id "$zone_id" "$RECORD_NAME" "$RECORD_TYPE" "$ZONE_TYPE")
        if [ -z "$rs_id" ]; then
            color_print "$RED" "❌ 未找到要更新的 Record Set: ${RECORD_NAME} (${RECORD_TYPE})"
            echo "请确认记录集名称和类型是否正确" >&2
            log_audit "update" "Zone=${ZONE_NAME}, Name=${RECORD_NAME}, Type=${RECORD_TYPE}" "failed_not_found"
            exit 1
        fi

        color_print "$BLUE" "  找到现有 Record Set ID: ${rs_id}"

        # 构造 records JSON 数组
        local records_json
        records_json=$(records_to_json "$RECORDS")

        local raw_json
        if [ "$ZONE_TYPE" = "public" ]; then
            raw_json=$(run_hcloud DNS UpdateRecordSet \
                --zone_id="$zone_id" \
                --recordset_id="$rs_id" \
                --name="$RECORD_NAME" \
                --type="$RECORD_TYPE" \
                --records="$records_json" \
                --ttl="$TTL" 2>&1) || {
                color_print "$RED" "❌ 更新 Record Set 失败"
                echo "$raw_json" >&2
                log_audit "update" "Zone=${ZONE_NAME}, Name=${RECORD_NAME}, Type=${RECORD_TYPE}, Records=${RECORDS}" "failed"
                exit 1
            }
        else
            raw_json=$(run_hcloud DNS UpdatePrivateRecordSet \
                --zone_id="$zone_id" \
                --recordset_id="$rs_id" \
                --name="$RECORD_NAME" \
                --type="$RECORD_TYPE" \
                --records="$records_json" \
                --ttl="$TTL" 2>&1) || {
                color_print "$RED" "❌ 更新私网 Record Set 失败"
                echo "$raw_json" >&2
                log_audit "update" "Zone=${ZONE_NAME}, Name=${RECORD_NAME}, Type=${RECORD_TYPE}, Records=${RECORDS}" "failed"
                exit 1
            }
        fi

        color_print "$GREEN" "✅ Record Set 更新成功！"
        echo "  Zone:        ${ZONE_NAME} (${ZONE_TYPE})"
        echo "  名称:        ${RECORD_NAME}"
        echo "  类型:        ${RECORD_TYPE}"
        echo "  记录值:      ${RECORDS}"
        echo "  TTL:         ${TTL}"
        echo "  Record Set ID: ${rs_id}"

        log_audit "update" "Zone=${ZONE_NAME}, Name=${RECORD_NAME}, Type=${RECORD_TYPE}, Records=${RECORDS}, TTL=${TTL}, ID=${rs_id}" "success"
        exit 0
    fi

    # ── 删除 Record Set ────────────────────────────────────────────
    if [ "$ACTION" = "delete" ]; then
        color_print "$CYAN" "🗑️  删除 Record Set: ${RECORD_NAME} (${RECORD_TYPE})..."

        # 查找现有 Record Set ID
        local rs_id
        rs_id=$(find_recordset_id "$zone_id" "$RECORD_NAME" "$RECORD_TYPE" "$ZONE_TYPE")
        if [ -z "$rs_id" ]; then
            color_print "$RED" "❌ 未找到要删除的 Record Set: ${RECORD_NAME} (${RECORD_TYPE})"
            echo "请确认记录集名称和类型是否正确" >&2
            log_audit "delete" "Zone=${ZONE_NAME}, Name=${RECORD_NAME}, Type=${RECORD_TYPE}" "failed_not_found"
            exit 1
        fi

        color_print "$BLUE" "  找到 Record Set ID: ${rs_id}"

        local raw_json
        if [ "$ZONE_TYPE" = "public" ]; then
            raw_json=$(run_hcloud DNS DeleteRecordSet \
                --zone_id="$zone_id" \
                --recordset_id="$rs_id" 2>&1) || {
                color_print "$RED" "❌ 删除 Record Set 失败"
                echo "$raw_json" >&2
                log_audit "delete" "Zone=${ZONE_NAME}, Name=${RECORD_NAME}, Type=${RECORD_TYPE}, ID=${rs_id}" "failed"
                exit 1
            }
        else
            raw_json=$(run_hcloud DNS DeletePrivateRecordSet \
                --zone_id="$zone_id" \
                --recordset_id="$rs_id" 2>&1) || {
                color_print "$RED" "❌ 删除私网 Record Set 失败"
                echo "$raw_json" >&2
                log_audit "delete" "Zone=${ZONE_NAME}, Name=${RECORD_NAME}, Type=${RECORD_TYPE}, ID=${rs_id}" "failed"
                exit 1
            }
        fi

        color_print "$GREEN" "✅ Record Set 删除成功！"
        echo "  Zone:        ${ZONE_NAME} (${ZONE_TYPE})"
        echo "  名称:        ${RECORD_NAME}"
        echo "  类型:        ${RECORD_TYPE}"
        echo "  Record Set ID: ${rs_id}"

        log_audit "delete" "Zone=${ZONE_NAME}, Name=${RECORD_NAME}, Type=${RECORD_TYPE}, ID=${rs_id}" "success"
        exit 0
    fi
}

main