#!/bin/bash
set -euo pipefail
# update_dns.sh - 批量 DNS 更新（故障切换 / 流量切换 / 蓝绿部署）
#
# 功能：
#   - failover 模式: 列出 Zone 内所有 A 记录，找到包含 old-ip 的记录，更新为 new-ip
#   - switch 模式:   将指定的命名记录更新为 new-ip
#   - bluegreen 模式: 读取 JSON 配置文件中的 updates 数组，逐条应用更新
#   - 支持 --dry-run 预览变更
#   - 所有操作写入审计日志
#
# 用法：
#   bash update_dns.sh --mode <mode> [OPTIONS]
#
# 参数：
#   --mode        必填  更新模式: failover/switch/bluegreen
#   --zone-name   必填* Zone 名称（FQDN 带末尾点，failover/switch 必填）
#   --zone-type   可选  Zone 类型: public/private，默认 public
#   --old-ip      必填* 旧 IP（failover 必填）
#   --new-ip      必填* 新 IP（failover/switch 必填）
#   --names       必填* 空格分隔的记录名称（switch 必填）
#   --type        可选  记录类型（switch 模式），默认 A
#   --config-file 必填* JSON 配置文件路径（bluegreen 必填）
#   --dry-run     可选  预览变更而不实际执行

source "$(dirname "$0")/config.sh"

# ── 默认值 ────────────────────────────────────────────────────────
MODE=""
ZONE_NAME=""
ZONE_TYPE="public"
OLD_IP=""
NEW_IP=""
NAMES=""
RECORD_TYPE="A"
CONFIG_FILE=""
DRY_RUN=false
SCRIPT_DIR="$(dirname "$0")"

# 统计计数器
COUNT_UPDATED=0
COUNT_SKIPPED=0
COUNT_FAILED=0

# ── 帮助 ──────────────────────────────────────────────────────────
usage() {
    cat <<'EOF'
用法: update_dns.sh --mode <mode> [OPTIONS]

必填参数:
  --mode <mode>              更新模式: failover/switch/bluegreen

模式特定参数:
  failover 模式:
    --zone-name <zone>       Zone 名称（FQDN 带末尾点，如 example.com.）
    --old-ip <ip>            要查找并替换的旧 IP
    --new-ip <ip>            替换为的新 IP

  switch 模式:
    --zone-name <zone>       Zone 名称（FQDN 带末尾点）
    --names <names>          空格分隔的记录名称（如 "www.example.com. api.example.com."）
    --new-ip <ip>            替换为的新 IP
    --type <type>            记录类型（默认: A）

  bluegreen 模式:
    --config-file <path>     JSON 配置文件路径

可选参数:
  --zone-type <type>         Zone 类型: public/private（默认: public）
  --dry-run                  预览变更而不实际执行
  --help, -h                 显示此帮助信息

示例:
  # 故障切换：将 Zone 内所有包含旧 IP 的 A 记录更新为新 IP
  update_dns.sh --mode failover --zone-name example.com. --old-ip 192.168.1.100 --new-ip 192.168.2.200

  # 流量切换：将指定记录更新为新 IP
  update_dns.sh --mode switch --zone-name example.com. --names "www.example.com. api.example.com." --new-ip 192.168.2.200

  # 蓝绿部署：使用 JSON 配置文件
  update_dns.sh --mode bluegreen --config-file ./dns-update-config.json

  # 预览模式
  update_dns.sh --mode failover --zone-name example.com. --old-ip 192.168.1.100 --new-ip 192.168.2.200 --dry-run
EOF
    exit 0
}

# ── 参数解析 ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)        MODE="$2"; shift 2 ;;
        --zone-name)   ZONE_NAME="$2"; shift 2 ;;
        --zone-type)   ZONE_TYPE="$2"; shift 2 ;;
        --old-ip)      OLD_IP="$2"; shift 2 ;;
        --new-ip)      NEW_IP="$2"; shift 2 ;;
        --names)       NAMES="$2"; shift 2 ;;
        --type)        RECORD_TYPE="$2"; shift 2 ;;
        --config-file) CONFIG_FILE="$2"; shift 2 ;;
        --dry-run)     DRY_RUN=true; shift ;;
        --help|-h)     usage ;;
        *)             color_print "$RED" "❌ 未知参数: $1"; usage ;;
    esac
done

# ── 校验必填参数 ──────────────────────────────────────────────────
if [[ -z "$MODE" ]]; then
    color_print "$RED" "❌ --mode 为必填参数"
    usage
fi

case "$MODE" in
    failover)
        if [[ -z "$ZONE_NAME" || -z "$OLD_IP" || -z "$NEW_IP" ]]; then
            color_print "$RED" "❌ failover 模式需要: --zone-name, --old-ip, --new-ip"
            usage
        fi
        ;;
    switch)
        if [[ -z "$ZONE_NAME" || -z "$NAMES" || -z "$NEW_IP" ]]; then
            color_print "$RED" "❌ switch 模式需要: --zone-name, --names, --new-ip"
            usage
        fi
        ;;
    bluegreen)
        if [[ -z "$CONFIG_FILE" ]]; then
            color_print "$RED" "❌ bluegreen 模式需要: --config-file"
            usage
        fi
        if [[ ! -f "$CONFIG_FILE" ]]; then
            color_print "$RED" "❌ 配置文件不存在: ${CONFIG_FILE}"
            exit 1
        fi
        ;;
    *)
        color_print "$RED" "❌ 不支持的模式: ${MODE} (仅支持 failover/switch/bluegreen)"
        usage
        ;;
esac

# ── 审计日志辅助函数 ──────────────────────────────────────────────
log_audit() {
    local detail="$1"
    if [[ -f "${SCRIPT_DIR}/dns_audit_log.sh" ]]; then
        bash "${SCRIPT_DIR}/dns_audit_log.sh" --action batch --detail "$detail" 2>/dev/null || true
    fi
}

# ── 获取 Zone ID ──────────────────────────────────────────────────
get_zone_id() {
    local zone_name="$1"
    local zone_type="$2"
    local zone_id

    if [[ "$zone_type" == "public" ]]; then
        zone_id=$(run_hcloud DNS ListPublicZones 2>/dev/null | jq -r ".zones[] | select(.name == \"${zone_name}\") | .id" 2>/dev/null | head -1) || zone_id=""
    else
        zone_id=$(run_hcloud DNS ListPrivateZones 2>/dev/null | jq -r ".zones[] | select(.name == \"${zone_name}\") | .id" 2>/dev/null | head -1) || zone_id=""
    fi

    echo "${zone_id:-}"
}

# ── 列出 Zone 内所有记录集 ────────────────────────────────────────
list_recordsets() {
    local zone_id="$1"
    local zone_type="$2"

    if [[ "$zone_type" == "public" ]]; then
        run_hcloud DNS ListRecordSets --zone_id="${zone_id}" 2>/dev/null || echo "{}"
    else
        run_hcloud DNS ListPrivateRecordSets --zone_id="${zone_id}" 2>/dev/null || echo "{}"
    fi
}

# ── 更新单个记录集 ────────────────────────────────────────────────
update_recordset() {
    local zone_id="$1"
    local zone_type="$2"
    local rs_name="$3"
    local rs_type="$4"
    local rs_records="$5"
    local rs_ttl="${6:-300}"
    local rs_id="$7"

    if [[ "$DRY_RUN" == "true" ]]; then
        color_print "$YELLOW" "   [DRY-RUN] 将更新记录: ${rs_name} (${rs_type}) -> ${rs_records} (TTL: ${rs_ttl})"
        return 0
    fi

    # 构造 records 参数（JSON 数组格式）
    local records_json
    records_json=$(echo "$rs_records" | tr ' ' '\n' | jq -R . | jq -s .)

    local result
    if [[ "$zone_type" == "public" ]]; then
        result=$(run_hcloud DNS UpdateRecordSet \
            --zone_id="${zone_id}" \
            --recordset_id="${rs_id}" \
            --name="${rs_name}" \
            --type="${rs_type}" \
            --records="${rs_records}" \
            --ttl="${rs_ttl}" 2>&1) || true
    else
        result=$(run_hcloud DNS UpdatePrivateRecordSet \
            --zone_id="${zone_id}" \
            --recordset_id="${rs_id}" \
            --name="${rs_name}" \
            --type="${rs_type}" \
            --records="${rs_records}" \
            --ttl="${rs_ttl}" 2>&1) || true
    fi

    if echo "$result" | jq -e '.id' >/dev/null 2>&1; then
        color_print "$GREEN" "   ✅ 已更新: ${rs_name} (${rs_type}) -> ${rs_records}"
        return 0
    else
        color_print "$RED" "   ❌ 更新失败: ${rs_name} - ${result}"
        return 1
    fi
}

# ── failover 模式 ────────────────────────────────────────────────
run_failover() {
    color_print "$CYAN" "🚀 故障切换模式"
    color_print "$CYAN" "   Zone: ${ZONE_NAME} (${ZONE_TYPE})"
    color_print "$CYAN" "   旧 IP: ${OLD_IP} → 新 IP: ${NEW_IP}"
    if [[ "$DRY_RUN" == "true" ]]; then
        color_print "$YELLOW" "   ⚠️  DRY-RUN 模式：仅预览，不实际执行"
    fi
    echo ""

    # 获取 Zone ID
    local zone_id
    zone_id=$(get_zone_id "$ZONE_NAME" "$ZONE_TYPE")
    if [[ -z "$zone_id" ]]; then
        color_print "$RED" "❌ 未找到 Zone: ${ZONE_NAME} (${ZONE_TYPE})"
        log_audit "failover 失败: Zone ${ZONE_NAME} 未找到"
        exit 1
    fi
    color_print "$GREEN" "✅ 找到 Zone ID: ${zone_id}"
    echo ""

    # 列出所有 A 记录集
    color_print "$CYAN" "📋 正在列出 Zone 内所有 A 记录集..."
    local rs_json
    rs_json=$(list_recordsets "$zone_id" "$ZONE_TYPE")

    # 提取包含 old-ip 的 A 记录
    local matching_count
    matching_count=$(echo "$rs_json" | jq -r ".recordsets[]? | select(.type == \"A\") | select(.records[] | contains(\"${OLD_IP}\")) | .name" 2>/dev/null | wc -l) || matching_count=0

    if [[ "$matching_count" -eq 0 ]]; then
        color_print "$YELLOW" "⚠️  未找到包含 IP ${OLD_IP} 的 A 记录"
        COUNT_SKIPPED=0
        print_summary
        log_audit "failover: Zone ${ZONE_NAME} 中未找到包含 ${OLD_IP} 的 A 记录"
        return 0
    fi

    color_print "$GREEN" "找到 ${matching_count} 个包含 ${OLD_IP} 的 A 记录"
    echo ""

    # 遍历匹配的记录集并更新
    local rs_names rs_ids rs_records rs_ttls
    rs_names=$(echo "$rs_json" | jq -r ".recordsets[]? | select(.type == \"A\") | select(.records[] | contains(\"${OLD_IP}\")) | .name" 2>/dev/null)
    rs_ids=$(echo "$rs_json" | jq -r ".recordsets[]? | select(.type == \"A\") | select(.records[] | contains(\"${OLD_IP}\")) | .id" 2>/dev/null)

    local i=0
    local names_arr=($rs_names)
    local ids_arr=($rs_ids)

    for idx in "${!names_arr[@]}"; do
        local rs_name="${names_arr[$idx]}"
        local rs_id="${ids_arr[$idx]}"

        # 获取当前记录值
        local current_records
        current_records=$(echo "$rs_json" | jq -r ".recordsets[]? | select(.id == \"${rs_id}\") | .records[]" 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//')

        # 获取 TTL
        local current_ttl
        current_ttl=$(echo "$rs_json" | jq -r ".recordsets[]? | select(.id == \"${rs_id}\") | .ttl // 300" 2>/dev/null) || current_ttl=300

        # 替换 old-ip 为 new-ip
        local new_records
        new_records=$(echo "$current_records" | sed "s/${OLD_IP}/${NEW_IP}/g")

        color_print "$BLUE" "📝 记录: ${rs_name}"
        color_print "$BLUE" "   旧值: ${current_records}"
        color_print "$BLUE" "   新值: ${new_records}"

        if update_recordset "$zone_id" "$ZONE_TYPE" "$rs_name" "A" "$new_records" "$current_ttl" "$rs_id"; then
            ((COUNT_UPDATED++))
            log_audit "failover 更新: ${rs_name} A 记录 ${OLD_IP} → ${NEW_IP}"
        else
            ((COUNT_FAILED++))
            log_audit "failover 更新失败: ${rs_name} A 记录"
        fi
        echo ""
    done

    print_summary
}

# ── switch 模式 ───────────────────────────────────────────────────
run_switch() {
    color_print "$CYAN" "🚀 流量切换模式"
    color_print "$CYAN" "   Zone: ${ZONE_NAME} (${ZONE_TYPE})"
    color_print "$CYAN" "   记录类型: ${RECORD_TYPE}"
    color_print "$CYAN" "   新 IP: ${NEW_IP}"
    if [[ "$DRY_RUN" == "true" ]]; then
        color_print "$YELLOW" "   ⚠️  DRY-RUN 模式：仅预览，不实际执行"
    fi
    echo ""

    # 获取 Zone ID
    local zone_id
    zone_id=$(get_zone_id "$ZONE_NAME" "$ZONE_TYPE")
    if [[ -z "$zone_id" ]]; then
        color_print "$RED" "❌ 未找到 Zone: ${ZONE_NAME} (${ZONE_TYPE})"
        log_audit "switch 失败: Zone ${ZONE_NAME} 未找到"
        exit 1
    fi
    color_print "$GREEN" "✅ 找到 Zone ID: ${zone_id}"
    echo ""

    # 列出所有记录集以获取记录 ID
    local rs_json
    rs_json=$(list_recordsets "$zone_id" "$ZONE_TYPE")

    # 遍历指定的记录名称
    local names_arr=($NAMES)
    for rs_name in "${names_arr[@]}"; do
        color_print "$BLUE" "📝 处理记录: ${rs_name}"

        # 查找记录集 ID
        local rs_id
        rs_id=$(echo "$rs_json" | jq -r ".recordsets[]? | select(.name == \"${rs_name}\" and .type == \"${RECORD_TYPE}\") | .id" 2>/dev/null | head -1) || rs_id=""

        if [[ -z "$rs_id" ]]; then
            color_print "$YELLOW" "   ⚠️  未找到记录集: ${rs_name} (${RECORD_TYPE})，跳过"
            ((COUNT_SKIPPED++))
            echo ""
            continue
        fi

        # 获取当前 TTL
        local current_ttl
        current_ttl=$(echo "$rs_json" | jq -r ".recordsets[]? | select(.id == \"${rs_id}\") | .ttl // 300" 2>/dev/null) || current_ttl=300

        color_print "$BLUE" "   记录 ID: ${rs_id}"
        color_print "$BLUE" "   新值: ${NEW_IP}"

        if update_recordset "$zone_id" "$ZONE_TYPE" "$rs_name" "$RECORD_TYPE" "$NEW_IP" "$current_ttl" "$rs_id"; then
            ((COUNT_UPDATED++))
            log_audit "switch 更新: ${rs_name} ${RECORD_TYPE} 记录 → ${NEW_IP}"
        else
            ((COUNT_FAILED++))
            log_audit "switch 更新失败: ${rs_name} ${RECORD_TYPE} 记录"
        fi
        echo ""
    done

    print_summary
}

# ── bluegreen 模式 ───────────────────────────────────────────────
run_bluegreen() {
    color_print "$CYAN" "🚀 蓝绿部署模式"
    color_print "$CYAN" "   配置文件: ${CONFIG_FILE}"
    if [[ "$DRY_RUN" == "true" ]]; then
        color_print "$YELLOW" "   ⚠️  DRY-RUN 模式：仅预览，不实际执行"
    fi
    echo ""

    # 从配置文件读取 zone 信息
    local bg_zone_name bg_zone_type
    bg_zone_name=$(jq -r '.zone_name // empty' "$CONFIG_FILE" 2>/dev/null) || bg_zone_name=""
    bg_zone_type=$(jq -r '.zone_type // "public"' "$CONFIG_FILE" 2>/dev/null) || bg_zone_type="public"

    if [[ -z "$bg_zone_name" ]]; then
        color_print "$RED" "❌ 配置文件中缺少 zone_name 字段"
        exit 1
    fi

    color_print "$CYAN" "   Zone: ${bg_zone_name} (${bg_zone_type})"
    echo ""

    # 获取 Zone ID
    local zone_id
    zone_id=$(get_zone_id "$bg_zone_name" "$bg_zone_type")
    if [[ -z "$zone_id" ]]; then
        color_print "$RED" "❌ 未找到 Zone: ${bg_zone_name} (${bg_zone_type})"
        log_audit "bluegreen 失败: Zone ${bg_zone_name} 未找到"
        exit 1
    fi
    color_print "$GREEN" "✅ 找到 Zone ID: ${zone_id}"
    echo ""

    # 列出所有记录集以获取记录 ID
    local rs_json
    rs_json=$(list_recordsets "$zone_id" "$bg_zone_type")

    # 读取 updates 数组
    local update_count
    update_count=$(jq '.updates | length' "$CONFIG_FILE" 2>/dev/null) || update_count=0

    if [[ "$update_count" -eq 0 ]]; then
        color_print "$YELLOW" "⚠️  配置文件中没有 updates 条目"
        print_summary
        return 0
    fi

    color_print "$CYAN" "📋 共 ${update_count} 条更新"
    echo ""

    # 遍历 updates 数组
    for i in $(seq 0 $((update_count - 1))); do
        local u_name u_type u_records u_ttl
        u_name=$(jq -r ".updates[${i}].name // empty" "$CONFIG_FILE" 2>/dev/null) || u_name=""
        u_type=$(jq -r ".updates[${i}].type // \"A\"" "$CONFIG_FILE" 2>/dev/null) || u_type="A"
        u_ttl=$(jq -r ".updates[${i}].ttl // 300" "$CONFIG_FILE" 2>/dev/null) || u_ttl=300

        # records 可能是数组或字符串
        u_records=$(jq -r ".updates[${i}].records[]?" "$CONFIG_FILE" 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//') || u_records=""
        if [[ -z "$u_records" ]]; then
            u_records=$(jq -r ".updates[${i}].records // empty" "$CONFIG_FILE" 2>/dev/null) || u_records=""
        fi

        if [[ -z "$u_name" || -z "$u_records" ]]; then
            color_print "$YELLOW" "⚠️  跳过无效条目 #${i}: 缺少 name 或 records"
            ((COUNT_SKIPPED++))
            echo ""
            continue
        fi

        color_print "$BLUE" "📝 记录: ${u_name} (${u_type})"
        color_print "$BLUE" "   值: ${u_records}"
        color_print "$BLUE" "   TTL: ${u_ttl}"

        # 查找记录集 ID
        local rs_id
        rs_id=$(echo "$rs_json" | jq -r ".recordsets[]? | select(.name == \"${u_name}\" and .type == \"${u_type}\") | .id" 2>/dev/null | head -1) || rs_id=""

        if [[ -z "$rs_id" ]]; then
            color_print "$YELLOW" "   ⚠️  未找到记录集: ${u_name} (${u_type})，跳过"
            ((COUNT_SKIPPED++))
            echo ""
            continue
        fi

        if update_recordset "$zone_id" "$bg_zone_type" "$u_name" "$u_type" "$u_records" "$u_ttl" "$rs_id"; then
            ((COUNT_UPDATED++))
            log_audit "bluegreen 更新: ${u_name} ${u_type} 记录 → ${u_records}"
        else
            ((COUNT_FAILED++))
            log_audit "bluegreen 更新失败: ${u_name} ${u_type} 记录"
        fi
        echo ""
    done

    print_summary
}

# ── 打印汇总 ──────────────────────────────────────────────────────
print_summary() {
    echo ""
    color_print "$BOLD" "════════════════════════════════════════"
    color_print "$BOLD" "  批量更新汇总"
    color_print "$BOLD" "════════════════════════════════════════"
    color_print "$GREEN" "  ✅ 已更新: ${COUNT_UPDATED}"
    color_print "$YELLOW" "  ⏭️  已跳过: ${COUNT_SKIPPED}"
    color_print "$RED" "  ❌ 已失败: ${COUNT_FAILED}"
    color_print "$BOLD" "════════════════════════════════════════"

    log_audit "批量更新完成: ${COUNT_UPDATED} updated, ${COUNT_SKIPPED} skipped, ${COUNT_FAILED} failed (mode: ${MODE})"
}

# ── 主逻辑 ────────────────────────────────────────────────────────
case "$MODE" in
    failover)  run_failover ;;
    switch)    run_switch ;;
    bluegreen) run_bluegreen ;;
esac