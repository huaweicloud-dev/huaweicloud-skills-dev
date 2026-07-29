#!/bin/bash
# list_recordsets.sh - 列出指定 Zone 内的所有 Record Set
# 基于 hcloud CLI（KooCLI）
#
# Usage:
#   bash list_recordsets.sh --zone-name example.com.
#   bash list_recordsets.sh --zone-name example.com. --zone-type private
#   bash list_recordsets.sh --zone-name example.com. --type A
#   bash list_recordsets.sh --zone-name example.com. --name www.example.com.
#   bash list_recordsets.sh --zone-name example.com. --search www
#   bash list_recordsets.sh --zone-name example.com. --format json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# ── 参数解析 ──────────────────────────────────────────────────────
ZONE_NAME=""
ZONE_TYPE="public"
RECORD_TYPE=""
RECORD_NAME=""
SEARCH=""
FORMAT="text"

while [[ $# -gt 0 ]]; do
    case $1 in
        --zone-name)  ZONE_NAME="$2"; shift 2 ;;
        --zone-type)  ZONE_TYPE="$2"; shift 2 ;;
        --type)       RECORD_TYPE="$2"; shift 2 ;;
        --name)       RECORD_NAME="$2"; shift 2 ;;
        --search)     SEARCH="$2"; shift 2 ;;
        --format)     FORMAT="$2"; shift 2 ;;
        --help|-h)
            echo "用法: $0 --zone-name <FQDN> [选项]"
            echo ""
            echo "必需参数："
            echo "  --zone-name    Zone 名称（FQDN，含末尾点，如 example.com.）"
            echo ""
            echo "可选参数："
            echo "  --zone-type    Zone 类型：public / private（默认：public）"
            echo "  --type         按记录类型过滤：A / AAAA / CNAME / MX / TXT / NS / SRV / CAA"
            echo "  --name         按记录集名称精确过滤"
            echo "  --search       按名称模式搜索（模糊匹配）"
            echo "  --format       输出格式：text（默认）/ json"
            echo ""
            echo "示例："
            echo "  $0 --zone-name example.com."
            echo "  $0 --zone-name example.com. --type A --format json"
            echo "  $0 --zone-name example.com. --zone-type private --search www"
            exit 0 ;;
        *) echo "未知选项: $1" >&2; exit 1 ;;
    esac
done

# 校验必需参数
if [ -z "$ZONE_NAME" ]; then
    color_print "$RED" "❌ 缺少必需参数: --zone-name"
    echo "使用 --help 查看用法" >&2
    exit 1
fi

case "$ZONE_TYPE" in
    public|private) ;;
    *) color_print "$RED" "❌ 不支持的 zone 类型: '$ZONE_TYPE'（仅支持 public / private）" >&2; exit 1 ;;
esac

case "$FORMAT" in
    text|json) ;;
    *) color_print "$RED" "❌ 不支持的格式: '$FORMAT'（仅支持 text / json）" >&2; exit 1 ;;
esac

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

    # 精确匹配 zone 名称
    local zone_id
    zone_id=$(echo "$zones_json" | jq -r --arg name "$target_name" '.[] | select(.name == $name) | .id' | head -1)

    if [ -z "$zone_id" ] || [ "$zone_id" = "null" ]; then
        color_print "$RED" "❌ 未找到 Zone: ${target_name}（类型: ${target_type}）"
        echo "请检查 Zone 名称是否正确（需包含末尾点，如 example.com.）" >&2
        return 1
    fi

    echo "$zone_id"
}

# ── 查询 Record Set 列表 ──────────────────────────────────────────
fetch_recordsets() {
    local zone_id="$1"
    local ztype="$2"
    local raw_json

    if [ "$ztype" = "public" ]; then
        raw_json=$(run_hcloud DNS ListRecordSets --zone_id="$zone_id" --limit=1000 2>/dev/null) || {
            color_print "$RED" "❌ 查询公网 Record Set 列表失败（Zone ID: ${zone_id}）"
            return 1
        }
    else
        raw_json=$(run_hcloud DNS ListPrivateRecordSets --zone_id="$zone_id" --limit=1000 2>/dev/null) || {
            color_print "$RED" "❌ 查询私网 Record Set 列表失败（Zone ID: ${zone_id}）"
            return 1
        }
    fi

    if [ -z "$raw_json" ] || ! echo "$raw_json" | jq -e '.recordsets' >/dev/null 2>&1; then
        color_print "$RED" "❌ API 返回异常，请检查 Zone ID ${zone_id} 是否有效"
        return 1
    fi

    echo "$raw_json" | jq -c '.recordsets'
}

# ── 主逻辑 ────────────────────────────────────────────────────────
main() {
    # 查找 Zone ID
    color_print "$CYAN" "🔍 查找 Zone: ${ZONE_NAME}（类型: ${ZONE_TYPE}）..."

    local zone_id
    zone_id=$(find_zone_id "$ZONE_NAME" "$ZONE_TYPE") || exit 1

    color_print "$GREEN" "✅ 找到 Zone ID: ${zone_id}"
    echo ""

    # 查询 Record Sets
    local recordsets_json
    recordsets_json=$(fetch_recordsets "$zone_id" "$ZONE_TYPE") || exit 1

    local total_count
    total_count=$(echo "$recordsets_json" | jq 'length')

    if [ "$total_count" -eq 0 ]; then
        if [ "$FORMAT" = "json" ]; then
            local ts
            ts=$(date '+%Y-%m-%dT%H:%M:%S+08:00')
            jq -n -c \
                --arg region "$HW_REGION" \
                --arg timestamp "$ts" \
                --arg zone_name "$ZONE_NAME" \
                --arg zone_id "$zone_id" \
                --arg zone_type "$ZONE_TYPE" \
                --argjson count 0 \
                --argjson recordsets '[]' \
                '{region: $region, timestamp: $timestamp, zone_name: $zone_name, zone_id: $zone_id, zone_type: $zone_type, count: $count, recordsets: $recordsets}' | jq .
        else
            color_print "$YELLOW" "⚠️  Zone ${ZONE_NAME} 中没有 Record Set"
        fi
        exit 0
    fi

    # ── 过滤 ──────────────────────────────────────────────────────
    # 按记录类型过滤
    if [ -n "$RECORD_TYPE" ]; then
        recordsets_json=$(echo "$recordsets_json" | jq -c --arg t "$RECORD_TYPE" '[.[] | select(.type == $t)]')
    fi

    # 按记录集名称精确过滤
    if [ -n "$RECORD_NAME" ]; then
        recordsets_json=$(echo "$recordsets_json" | jq -c --arg n "$RECORD_NAME" '[.[] | select(.name == $n)]')
    fi

    # 按名称模式搜索
    if [ -n "$SEARCH" ]; then
        recordsets_json=$(echo "$recordsets_json" | jq -c --arg p "$SEARCH" '[.[] | select(.name | test($p; "i"))]')
    fi

    local filtered_count
    filtered_count=$(echo "$recordsets_json" | jq 'length')

    if [ "$filtered_count" -eq 0 ]; then
        if [ "$FORMAT" = "json" ]; then
            local ts
            ts=$(date '+%Y-%m-%dT%H:%M:%S+08:00')
            jq -n -c \
                --arg region "$HW_REGION" \
                --arg timestamp "$ts" \
                --arg zone_name "$ZONE_NAME" \
                --arg zone_id "$zone_id" \
                --arg zone_type "$ZONE_TYPE" \
                --argjson count 0 \
                --argjson recordsets '[]' \
                '{region: $region, timestamp: $timestamp, zone_name: $zone_name, zone_id: $zone_id, zone_type: $zone_type, count: $count, recordsets: $recordsets}' | jq .
        else
            color_print "$YELLOW" "⚠️  未找到匹配的 Record Set（共 ${total_count} 条记录，过滤后 0 条）"
        fi
        exit 0
    fi

    # ── JSON 输出 ──────────────────────────────────────────────────
    if [ "$FORMAT" = "json" ]; then
        local ts
        ts=$(date '+%Y-%m-%dT%H:%M:%S+08:00')

        local rs_normalized
        rs_normalized=$(echo "$recordsets_json" | jq -c '[
            .[] | {
                name: .name,
                type: .type,
                ttl: .ttl,
                records: (.records // []),
                status: .status,
                record_set_id: .id
            }
        ]')

        jq -n -c \
            --arg region "$HW_REGION" \
            --arg timestamp "$ts" \
            --arg zone_name "$ZONE_NAME" \
            --arg zone_id "$zone_id" \
            --arg zone_type "$ZONE_TYPE" \
            --argjson count "$filtered_count" \
            --argjson recordsets "$rs_normalized" \
            '{region: $region, timestamp: $timestamp, zone_name: $zone_name, zone_id: $zone_id, zone_type: $zone_type, count: $count, recordsets: $recordsets}' | jq .
        exit 0
    fi

    # ── 文本输出 ──────────────────────────────────────────────────
    color_print "$BLUE" "============================================================"
    color_print "$BLUE" "  Record Set 列表（Zone: ${ZONE_NAME} [${ZONE_TYPE}]）"
    color_print "$BLUE" "============================================================"
    echo ""

    local idx=0
    while IFS= read -r row; do
        local name rtype ttl records status rs_id

        name=$(echo "$row" | jq -r '.name // "N/A"')
        rtype=$(echo "$row" | jq -r '.type // "N/A"')
        ttl=$(echo "$row" | jq -r '.ttl // "N/A"')
        records=$(echo "$row" | jq -r '(.records // []) | join(", ")')
        status=$(echo "$row" | jq -r '.status // "UNKNOWN"')
        rs_id=$(echo "$row" | jq -r '.id // "N/A"')

        idx=$((idx + 1))

        local status_color="$GREEN"
        if [ "$status" != "ACTIVE" ]; then
            status_color="$YELLOW"
        fi

        printf "[%d] ${BOLD}%s${RESET}  " "$idx" "$name"
        printf "${CYAN}%s${RESET}\n" "$rtype"
        echo "    Record Set ID: ${rs_id}"
        printf "    状态：         ${status_color}%s${RESET}\n" "$status"
        echo "    TTL：          ${ttl}"
        echo "    记录值：       ${records}"
        echo ""
    done < <(echo "$recordsets_json" | jq -c '.[]')

    color_print "$BLUE" "------------------------------------------------------------"
    color_print "$BOLD" "📊 汇总: 共 ${idx} 条 Record Set（Zone 内总计 ${total_count} 条）"
    color_print "$BLUE" "------------------------------------------------------------"
}

main