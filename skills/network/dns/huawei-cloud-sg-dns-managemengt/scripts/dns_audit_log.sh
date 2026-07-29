#!/bin/bash
set -euo pipefail
# dns_audit_log.sh - DNS 操作审计日志
#
# 功能：
#   - 将 DNS 操作记录写入 JSONL 日志文件（每行一个 JSON 对象）
#   - 支持导出为 CSV 或 JSON 数组格式
#   - 时间戳为时区感知格式：YYYY-MM-DDTHH:MM:SS+HH:MM
#
# 用法：
#   bash dns_audit_log.sh --action <action> [--detail <desc>] [--export csv|json] [--log-dir <dir>]
#
# 参数：
#   --action    必填  操作类型: list/create/update/delete/validate/batch
#   --detail    可选  操作描述
#   --export    可选  导出格式: csv/json
#   --log-dir   可选  日志目录，默认 ./dns_audit_logs

source "$(dirname "$0")/config.sh"

# ── 默认值 ────────────────────────────────────────────────────────
LOG_DIR="./dns_audit_logs"
ACTION=""
DETAIL=""
EXPORT=""
SCRIPT_DIR="$(dirname "$0")"

# ── 帮助 ──────────────────────────────────────────────────────────
usage() {
    cat <<'EOF'
用法: dns_audit_log.sh --action <action> [OPTIONS]

必填参数:
  --action <action>       操作类型: list/create/update/delete/validate/batch

可选参数:
  --detail <description>  操作描述信息
  --export <format>       导出格式: csv 或 json
  --log-dir <dir>         日志目录 (默认: ./dns_audit_logs)
  --help, -h              显示此帮助信息

示例:
  # 记录一次查询操作
  dns_audit_log.sh --action list --detail "Queried all public zones"

  # 记录一次更新操作
  dns_audit_log.sh --action update --detail "Updated A record www.example.com. to 192.168.2.200"

  # 导出为 CSV
  dns_audit_log.sh --action list --export csv

  # 导出为 JSON 数组
  dns_audit_log.sh --action list --export json

  # 自定义日志目录
  dns_audit_log.sh --action validate --detail "Validated www.example.com" --log-dir /var/log/dns_audit
EOF
    exit 0
}

# ── 参数解析 ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --action)       ACTION="$2"; shift 2 ;;
        --detail)       DETAIL="$2"; shift 2 ;;
        --export)       EXPORT="$2"; shift 2 ;;
        --log-dir)      LOG_DIR="$2"; shift 2 ;;
        --help|-h)      usage ;;
        *)              color_print "$RED" "❌ 未知参数: $1"; usage ;;
    esac
done

# ── 校验必填参数 ──────────────────────────────────────────────────
if [[ -z "$ACTION" ]]; then
    color_print "$RED" "❌ --action 为必填参数"
    usage
fi

# ── 创建日志目录 ──────────────────────────────────────────────────
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/dns_audit_$(date +%Y%m%d).jsonl"

# ── 生成时区感知时间戳 ────────────────────────────────────────────
# 格式: YYYY-MM-DDTHH:MM:SS+HH:MM
generate_timestamp() {
    local raw_ts
    raw_ts=$(date +%Y-%m-%dT%H:%M:%S%z)
    # 将 +0800 转换为 +08:00
    local sign="${raw_ts: -5:1}"
    local tz_h="${raw_ts: -4:2}"
    local tz_m="${raw_ts: -2:2}"
    local dt="${raw_ts:0:19}"
    echo "${dt}${sign}${tz_h}:${tz_m}"
}

# ── JSON 转义 ─────────────────────────────────────────────────────
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"    # 反斜杠
    s="${s//\"/\\\"}"    # 双引号
    s="${s//$'\n'/\\n}"  # 换行
    s="${s//$'\r'/\\r}"  # 回车
    s="${s//$'\t'/\\t}"  # 制表符
    echo "$s"
}

# ── 获取当前用户 ──────────────────────────────────────────────────
get_user() {
    whoami 2>/dev/null || echo "unknown"
}

# ── 写入审计日志 ──────────────────────────────────────────────────
write_log() {
    local timestamp action detail user region
    timestamp=$(generate_timestamp)
    action=$(json_escape "$ACTION")
    detail=$(json_escape "${DETAIL:-}")
    user=$(get_user)
    region="${HW_REGION:-unknown}"

    local entry
    entry="{\"timestamp\":\"${timestamp}\",\"region\":\"${region}\",\"action\":\"${action}\",\"detail\":\"${detail}\",\"user\":\"${user}\"}"

    echo "$entry" >> "$LOG_FILE"
    color_print "$GREEN" "✅ 审计日志已记录: ${LOG_FILE}"
    color_print "$CYAN" "   ${entry}"
}

# ── 导出为 CSV ────────────────────────────────────────────────────
export_csv() {
    local csv_file="${LOG_DIR}/dns_audit_export_$(date +%Y%m%d_%H%M%S).csv"
    echo "timestamp,region,action,detail,user" > "$csv_file"

    # 查找所有 JSONL 日志文件
    local found=0
    for f in "${LOG_DIR}"/dns_audit_*.jsonl; do
        [[ -f "$f" ]] || continue
        found=1
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            # 使用 jq 解析 JSONL 行并输出 CSV 格式
            echo "$line" | jq -r '[.timestamp, .region, .action, .detail, .user] | @csv' >> "$csv_file" 2>/dev/null || true
        done < "$f"
    done

    if [[ "$found" -eq 0 ]]; then
        color_print "$YELLOW" "⚠️  未找到任何日志文件"
        return 0
    fi

    color_print "$GREEN" "✅ CSV 导出完成: ${csv_file}"
    local count
    count=$(($(wc -l < "$csv_file") - 1))
    color_print "$CYAN" "   共 ${count} 条记录"
}

# ── 导出为 JSON 数组 ──────────────────────────────────────────────
export_json() {
    local json_file="${LOG_DIR}/dns_audit_export_$(date +%Y%m%d_%H%M%S).json"
    local found=0
    local all_entries="["

    for f in "${LOG_DIR}"/dns_audit_*.jsonl; do
        [[ -f "$f" ]] || continue
        found=1
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            if [[ "$all_entries" == "[" ]]; then
                all_entries="${all_entries}${line}"
            else
                all_entries="${all_entries},${line}"
            fi
        done < "$f"
    done

    all_entries="${all_entries}]"

    if [[ "$found" -eq 0 ]]; then
        color_print "$YELLOW" "⚠️  未找到任何日志文件"
        echo "[]" > "$json_file"
        color_print "$CYAN" "   空数组已写入: ${json_file}"
        return 0
    fi

    # 用 jq 格式化输出
    echo "$all_entries" | jq '.' > "$json_file" 2>/dev/null || echo "$all_entries" > "$json_file"

    color_print "$GREEN" "✅ JSON 导出完成: ${json_file}"
    local count
    count=$(jq 'length' "$json_file" 2>/dev/null || echo "0")
    color_print "$CYAN" "   共 ${count} 条记录"
}

# ── 主逻辑 ────────────────────────────────────────────────────────
if [[ -n "$EXPORT" ]]; then
    case "$EXPORT" in
        csv)  export_csv ;;
        json) export_json ;;
        *)
            color_print "$RED" "❌ 不支持的导出格式: ${EXPORT} (仅支持 csv/json)"
            exit 1
            ;;
    esac
else
    write_log
fi