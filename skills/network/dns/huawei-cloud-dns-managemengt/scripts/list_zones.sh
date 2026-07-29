#!/bin/bash
# list_zones.sh - 列出所有 DNS Zone（公网 / 私网）
# 基于 hcloud CLI（KooCLI）
#
# Usage:
#   bash list_zones.sh --type public
#   bash list_zones.sh --type private
#   bash list_zones.sh --type all
#   bash list_zones.sh --type public --search example
#   bash list_zones.sh --type public --format json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# ── 参数解析 ──────────────────────────────────────────────────────
ZONE_TYPE="all"
SEARCH=""
FORMAT="text"

while [[ $# -gt 0 ]]; do
    case $1 in
        --type)    ZONE_TYPE="$2"; shift 2 ;;
        --search)  SEARCH="$2"; shift 2 ;;
        --format)  FORMAT="$2"; shift 2 ;;
        --help|-h)
            echo "用法: $0 [--type public|private|all] [--search PATTERN] [--format text|json]"
            echo ""
            echo "选项："
            echo "  --type       Zone 类型：public / private / all（默认：all）"
            echo "  --search     按名称模式搜索（模糊匹配 zone 名称）"
            echo "  --format     输出格式：text（默认）/ json"
            echo ""
            echo "示例："
            echo "  $0 --type public"
            echo "  $0 --type public --search example --format json"
            exit 0 ;;
        *) echo "未知选项: $1" >&2; exit 1 ;;
    esac
done

# 校验参数
case "$ZONE_TYPE" in
    public|private|all) ;;
    *) color_print "$RED" "❌ 不支持的 zone 类型: '$ZONE_TYPE'（仅支持 public / private / all）" >&2; exit 1 ;;
esac

case "$FORMAT" in
    text|json) ;;
    *) color_print "$RED" "❌ 不支持的格式: '$FORMAT'（仅支持 text / json）" >&2; exit 1 ;;
esac

# ── 查询公网 Zone 列表 ────────────────────────────────────────────
fetch_public_zones() {
    local raw_json
    raw_json=$(run_hcloud DNS ListPublicZones --limit=1000 2>/dev/null) || {
        color_print "$RED" "❌ 查询公网 Zone 列表失败（区域 ${HW_REGION} 可能无效或凭证错误）"
        return 1
    }

    if [ -z "$raw_json" ] || ! echo "$raw_json" | jq -e '.zones' >/dev/null 2>&1; then
        color_print "$RED" "❌ API 返回异常，请检查区域 ${HW_REGION} 是否有效"
        return 1
    fi

    # 为每条记录添加 zone_type 标记
    echo "$raw_json" | jq -c '[.zones[] | . + {zone_type: "public"}]'
}

# ── 查询私网 Zone 列表 ────────────────────────────────────────────
fetch_private_zones() {
    local raw_json
    raw_json=$(run_hcloud DNS ListPrivateZones --limit=1000 2>/dev/null) || {
        color_print "$RED" "❌ 查询私网 Zone 列表失败（区域 ${HW_REGION} 可能无效或凭证错误）"
        return 1
    }

    if [ -z "$raw_json" ] || ! echo "$raw_json" | jq -e '.zones' >/dev/null 2>&1; then
        color_print "$RED" "❌ API 返回异常，请检查区域 ${HW_REGION} 是否有效"
        return 1
    fi

    echo "$raw_json" | jq -c '[.zones[] | . + {zone_type: "private"}]'
}

# ── 搜索过滤 ──────────────────────────────────────────────────────
filter_by_search() {
    local zones_json="$1"
    local pattern="$2"

    if [ -z "$pattern" ]; then
        echo "$zones_json"
    else
        echo "$zones_json" | jq -c --arg p "$pattern" '[.[] | select(.name | test($p; "i"))]'
    fi
}

# ── 主逻辑 ────────────────────────────────────────────────────────
main() {
    local all_zones='[]'

    # 根据类型查询
    case "$ZONE_TYPE" in
        public)
            all_zones=$(fetch_public_zones) || exit 1
            ;;
        private)
            all_zones=$(fetch_private_zones) || exit 1
            ;;
        all)
            local pub_zones priv_zones
            pub_zones=$(fetch_public_zones 2>/dev/null) || pub_zones='[]'
            priv_zones=$(fetch_private_zones 2>/dev/null) || priv_zones='[]'
            all_zones=$(echo "$pub_zones $priv_zones" | jq -s -c 'add')
            ;;
    esac

    # 搜索过滤
    all_zones=$(filter_by_search "$all_zones" "$SEARCH")

    local total_count
    total_count=$(echo "$all_zones" | jq 'length')

    if [ "$total_count" -eq 0 ]; then
        if [ "$FORMAT" = "json" ]; then
            local ts
            ts=$(date '+%Y-%m-%dT%H:%M:%S+08:00')
            jq -n -c \
                --arg region "$HW_REGION" \
                --arg timestamp "$ts" \
                --argjson count 0 \
                --argjson zones '[]' \
                '{region: $region, timestamp: $timestamp, count: $count, zones: $zones}' | jq .
        else
            color_print "$YELLOW" "⚠️  未找到匹配的 DNS Zone"
        fi
        exit 0
    fi

    # ── JSON 输出 ──────────────────────────────────────────────────
    if [ "$FORMAT" = "json" ]; then
        local ts
        ts=$(date '+%Y-%m-%dT%H:%M:%S+08:00')

        # 构造标准化的 zones 数组
        local zones_normalized
        zones_normalized=$(echo "$all_zones" | jq -c '[
            .[] | {
                name: .name,
                zone_id: .id,
                zone_type: .zone_type,
                status: .status,
                record_num: .record_num,
                ttl: .ttl,
                created_at: .created_at
            }
        ]')

        jq -n -c \
            --arg region "$HW_REGION" \
            --arg timestamp "$ts" \
            --argjson count "$total_count" \
            --argjson zones "$zones_normalized" \
            '{region: $region, timestamp: $timestamp, count: $count, zones: $zones}' | jq .
        exit 0
    fi

    # ── 文本输出 ──────────────────────────────────────────────────
    color_print "$BLUE" "============================================================"
    color_print "$BLUE" "  DNS Zone 列表（区域：${HW_REGION}，类型：${ZONE_TYPE}）"
    color_print "$BLUE" "============================================================"
    echo ""

    local idx=0
    while IFS= read -r row; do
        local name zone_id zone_type status record_num ttl created_at

        name=$(echo "$row" | jq -r '.name // "N/A"')
        zone_id=$(echo "$row" | jq -r '.id // "N/A"')
        zone_type=$(echo "$row" | jq -r '.zone_type // "N/A"')
        status=$(echo "$row" | jq -r '.status // "UNKNOWN"')
        record_num=$(echo "$row" | jq -r '.record_num // 0')
        ttl=$(echo "$row" | jq -r '.ttl // "N/A"')
        created_at=$(echo "$row" | jq -r '.created_at // "N/A"')

        idx=$((idx + 1))

        local status_color="$GREEN"
        if [ "$status" != "ACTIVE" ]; then
            status_color="$YELLOW"
        fi

        local type_color="$CYAN"
        if [ "$zone_type" = "private" ]; then
            type_color="$YELLOW"
        fi

        printf "[%d] ${BOLD}%s${RESET}  " "$idx" "$name"
        printf "(${type_color}%s${RESET})\n" "$zone_type"
        echo "    Zone ID:     ${zone_id}"
        printf "    状态：       ${status_color}%s${RESET}\n" "$status"
        echo "    记录数：     ${record_num}"
        echo "    TTL：        ${ttl}"
        if [ "$created_at" != "N/A" ]; then
            echo "    创建时间：   ${created_at}"
        fi
        echo ""
    done < <(echo "$all_zones" | jq -c '.[]')

    color_print "$BLUE" "------------------------------------------------------------"
    color_print "$BOLD" "📊 汇总: 共 ${idx} 个 Zone"
    color_print "$BLUE" "------------------------------------------------------------"
}

main