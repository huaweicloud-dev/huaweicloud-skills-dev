#!/bin/bash
set -euo pipefail
# validate_dns.sh - DNS 解析验证
#
# 功能：
#   - 使用 dig（优先）、nslookup（备选）、curl（最终回退）查询 DNS 解析
#   - 支持 A/AAAA/CNAME/MX/TXT/NS 等记录类型
#   - 将解析结果与期望值比较，输出 pass/fail 状态
#   - 无期望值时仅输出解析结果
#
# 用法：
#   bash validate_dns.sh --domain <domain> [--type <type>] [--expected-ip <ip>] [--expected-value <val>] [--dns-server <srv>] [--timeout <sec>]
#
# 参数：
#   --domain         必填  要验证的域名（不带末尾点）
#   --type           可选  记录类型: A/AAAA/CNAME/MX/TXT/NS，默认 A
#   --expected-ip    可选  期望的 IP 地址（用于 A/AAAA 记录）
#   --expected-value 可选  期望的记录值（用于 CNAME/MX/TXT/NS 等记录）
#   --dns-server     可选  指定 DNS 服务器进行查询
#   --timeout        可选  查询超时时间（秒），默认 5
#
# 退出码：
#   0 - 验证通过（解析结果与期望值匹配）
#   1 - 验证失败（不匹配或查询失败）

source "$(dirname "$0")/config.sh"

# ── 默认值 ────────────────────────────────────────────────────────
DOMAIN=""
RECORD_TYPE="A"
EXPECTED_IP=""
EXPECTED_VALUE=""
DNS_SERVER=""
TIMEOUT_SEC=5
SCRIPT_DIR="$(dirname "$0")"

# ── 帮助 ──────────────────────────────────────────────────────────
usage() {
    cat <<'EOF'
用法: validate_dns.sh --domain <domain> [OPTIONS]

必填参数:
  --domain <domain>            要验证的域名（不带末尾点，如 www.example.com）

可选参数:
  --type <type>                记录类型: A/AAAA/CNAME/MX/TXT/NS (默认: A)
  --expected-ip <ip>           期望的 IP 地址（用于 A/AAAA 记录）
  --expected-value <value>     期望的记录值（用于 CNAME/MX/TXT/NS 等记录）
  --dns-server <server>        指定 DNS 服务器进行查询（如 8.8.8.8）
  --timeout <seconds>          查询超时时间（默认: 5）
  --help, -h                   显示此帮助信息

示例:
  # 验证 A 记录解析
  validate_dns.sh --domain www.example.com --type A --expected-ip 192.168.1.100

  # 验证 CNAME 记录
  validate_dns.sh --domain api.example.com --type CNAME --expected-value lb.example.com.

  # 仅查询解析结果（不比较期望值）
  validate_dns.sh --domain www.example.com --type A

  # 使用指定 DNS 服务器
  validate_dns.sh --domain www.example.com --type A --dns-server 8.8.8.8

  # 设置超时时间
  validate_dns.sh --domain www.example.com --type A --timeout 10
EOF
    exit 0
}

# ── 参数解析 ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain)           DOMAIN="$2"; shift 2 ;;
        --type)             RECORD_TYPE="$2"; shift 2 ;;
        --expected-ip)      EXPECTED_IP="$2"; shift 2 ;;
        --expected-value)   EXPECTED_VALUE="$2"; shift 2 ;;
        --dns-server)       DNS_SERVER="$2"; shift 2 ;;
        --timeout)          TIMEOUT_SEC="$2"; shift 2 ;;
        --help|-h)          usage ;;
        *)                  color_print "$RED" "❌ 未知参数: $1"; usage ;;
    esac
done

# ── 校验必填参数 ──────────────────────────────────────────────────
if [[ -z "$DOMAIN" ]]; then
    color_print "$RED" "❌ --domain 为必填参数"
    usage
fi

# 去除域名末尾的点（如果有）
DOMAIN="${DOMAIN%.}"

# ── 审计日志辅助函数 ──────────────────────────────────────────────
log_audit() {
    local detail="$1"
    if [[ -f "${SCRIPT_DIR}/dns_audit_log.sh" ]]; then
        bash "${SCRIPT_DIR}/dns_audit_log.sh" --action validate --detail "$detail" 2>/dev/null || true
    fi
}

# ── 使用 dig 查询 ─────────────────────────────────────────────────
query_with_dig() {
    local query_domain="$1"
    local query_type="$2"
    local result

    if [[ -n "$DNS_SERVER" ]]; then
        result=$(dig +short +time="${TIMEOUT_SEC}" +tries=1 "@${DNS_SERVER}" "${query_domain}" "${query_type}" 2>/dev/null) || result=""
    else
        result=$(dig +short +time="${TIMEOUT_SEC}" +tries=1 "${query_domain}" "${query_type}" 2>/dev/null) || result=""
    fi

    # 过滤空行并去重
    result=$(echo "$result" | grep -v '^[[:space:]]*$' | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//')
    echo "$result"
}

# ── 使用 nslookup 查询 ────────────────────────────────────────────
query_with_nslookup() {
    local query_domain="$1"
    local query_type="$2"
    local result=""
    local nslookup_cmd

    if [[ -n "$DNS_SERVER" ]]; then
        nslookup_cmd=$(nslookup -timeout="${TIMEOUT_SEC}" -type="${query_type}" "${query_domain}" "${DNS_SERVER}" 2>/dev/null) || nslookup_cmd=""
    else
        nslookup_cmd=$(nslookup -timeout="${TIMEOUT_SEC}" -type="${query_type}" "${query_domain}" 2>/dev/null) || nslookup_cmd=""
    fi

    # 解析 nslookup 输出，提取记录值
    case "$query_type" in
        A|AAAA)
            result=$(echo "$nslookup_cmd" | grep -i 'Address' | grep -v '#' | awk '{print $NF}' | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//')
            ;;
        CNAME)
            result=$(echo "$nslookup_cmd" | grep -i 'canonical name' | awk '{print $NF}' | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//')
            ;;
        MX)
            result=$(echo "$nslookup_cmd" | grep -i 'mail exchanger' | awk '{print $NF}' | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//')
            ;;
        NS)
            result=$(echo "$nslookup_cmd" | grep -i 'nameserver' | awk '{print $NF}' | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//')
            ;;
        TXT)
            result=$(echo "$nslookup_cmd" | grep -i 'text' | awk '{$1=""; print}' | sed 's/^[[:space:]]*//' | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//')
            ;;
        *)
            result=$(echo "$nslookup_cmd" | grep -v '^[[:space:]]*$' | tail -n +4 | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//')
            ;;
    esac

    echo "$result"
}

# ── 使用 curl 查询（最终回退，使用 DoH）──────────────────────────
query_with_curl() {
    local query_domain="$1"
    local query_type="$2"
    local doh_url="https://dns.google/resolve"
    local result

    result=$(curl -s --max-time "${TIMEOUT_SEC}" "${doh_url}?name=${query_domain}&type=${query_type}" 2>/dev/null) || result=""

    if [[ -z "$result" ]]; then
        echo ""
        return
    fi

    # 使用 jq 提取 Answer 中的 data 字段
    if command -v jq >/dev/null 2>&1; then
        result=$(echo "$result" | jq -r '.Answer[]?.data // empty' 2>/dev/null | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//') || result=""
    fi

    echo "$result"
}

# ── 执行 DNS 查询 ─────────────────────────────────────────────────
color_print "$CYAN" "🔍 正在验证 DNS 解析..."
color_print "$CYAN" "   域名: ${DOMAIN}"
color_print "$CYAN" "   类型: ${RECORD_TYPE}"
if [[ -n "$DNS_SERVER" ]]; then
    color_print "$CYAN" "   DNS 服务器: ${DNS_SERVER}"
fi
color_print "$CYAN" "   超时: ${TIMEOUT_SEC} 秒"
echo ""

RESOLVED_VALUES=""
QUERY_METHOD=""

# 优先使用 dig
if command -v dig >/dev/null 2>&1; then
    QUERY_METHOD="dig"
    RESOLVED_VALUES=$(query_with_dig "$DOMAIN" "$RECORD_TYPE")
elif command -v nslookup >/dev/null 2>&1; then
    QUERY_METHOD="nslookup"
    RESOLVED_VALUES=$(query_with_nslookup "$DOMAIN" "$RECORD_TYPE")
elif command -v curl >/dev/null 2>&1; then
    QUERY_METHOD="curl (DoH)"
    RESOLVED_VALUES=$(query_with_curl "$DOMAIN" "$RECORD_TYPE")
else
    color_print "$RED" "❌ 未找到可用的 DNS 查询工具 (dig/nslookup/curl)"
    log_audit "DNS 验证失败: ${DOMAIN} ${RECORD_TYPE} - 无可用查询工具"
    exit 1
fi

# ── 输出解析结果 ──────────────────────────────────────────────────
color_print "$BLUE" "📡 查询方式: ${QUERY_METHOD}"
if [[ -n "$RESOLVED_VALUES" ]]; then
    color_print "$GREEN" "✅ 解析结果: ${RESOLVED_VALUES}"
else
    color_print "$YELLOW" "⚠️  未找到 ${RECORD_TYPE} 记录"
fi
echo ""

# ── 比较期望值 ────────────────────────────────────────────────────
EXPECTED=""
case "$RECORD_TYPE" in
    A|AAAA)
        EXPECTED="$EXPECTED_IP"
        ;;
    *)
        EXPECTED="$EXPECTED_VALUE"
        ;;
esac

if [[ -z "$EXPECTED" ]]; then
    # 无期望值，仅输出解析结果
    color_print "$GREEN" "✅ 验证完成（未指定期望值，仅输出解析结果）"
    log_audit "DNS 验证: ${DOMAIN} ${RECORD_TYPE} -> ${RESOLVED_VALUES} (无期望值比较)"
    exit 0
fi

color_print "$CYAN" "🎯 期望值: ${EXPECTED}"
echo ""

# 比较（支持多值匹配：期望值包含在解析结果中即视为通过）
if [[ -n "$RESOLVED_VALUES" ]]; then
    # 检查期望值是否出现在解析结果中
    if echo " $RESOLVED_VALUES " | grep -qF " $EXPECTED "; then
        color_print "$GREEN" "✅ 验证通过: 解析结果与期望值匹配"
        log_audit "DNS 验证通过: ${DOMAIN} ${RECORD_TYPE} -> ${RESOLVED_VALUES} (期望: ${EXPECTED})"
        exit 0
    else
        color_print "$RED" "❌ 验证失败: 解析结果与期望值不匹配"
        color_print "$RED" "   解析值: ${RESOLVED_VALUES}"
        color_print "$RED" "   期望值: ${EXPECTED}"
        log_audit "DNS 验证失败: ${DOMAIN} ${RECORD_TYPE} -> ${RESOLVED_VALUES} (期望: ${EXPECTED})"
        exit 1
    fi
else
    color_print "$RED" "❌ 验证失败: 未解析到任何记录"
    color_print "$RED" "   期望值: ${EXPECTED}"
    log_audit "DNS 验证失败: ${DOMAIN} ${RECORD_TYPE} -> 无解析结果 (期望: ${EXPECTED})"
    exit 1
fi