#!/bin/bash
# check_env.sh - 环境依赖检查脚本
# 检查 hcloud CLI、jq、curl、dig、nslookup 等依赖是否就绪
#
# Usage:
#   bash check_env.sh [--verbose] [--fix]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# ── 参数解析 ──────────────────────────────────────────────────────
VERBOSE=false
FIX=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v) VERBOSE=true; shift ;;
        --fix)        FIX=true; shift ;;
        --help|-h)
            echo "用法: $0 [--verbose] [--fix]"
            echo "  --verbose  显示详细检查信息"
            echo "  --fix      尝试自动修复缺失的依赖"
            exit 0 ;;
        *) echo "未知选项: $1" >&2; exit 1 ;;
    esac
done

# ── 检查结果统计 ──────────────────────────────────────────────────
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

check_pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    color_print "$GREEN" "  ✅ $1"
}

check_fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    color_print "$RED" "  ❌ $1"
}

check_warn() {
    WARN_COUNT=$((WARN_COUNT + 1))
    color_print "$YELLOW" "  ⚠️  $1"
}

# ── 依赖检查 ──────────────────────────────────────────────────────
echo ""
echo "================================================================"
echo "🔍 Huawei Cloud DNS Management 环境检查"
echo "================================================================"
echo ""

# 1. hcloud CLI
echo "1️⃣  核心依赖"
echo "──────────────────────────────────────"

if command -v hcloud >/dev/null 2>&1; then
    # hcloud path check
    hcloud_path=$(command -v hcloud)
    check_pass "hcloud CLI: ${hcloud_path}"

    if [ "$VERBOSE" = true ]; then
        hcloud_version=$(hcloud --version 2>/dev/null || echo "unknown")
        color_print "$BLUE" "     版本: ${hcloud_version}"
    fi
else
    check_fail "hcloud CLI 未安装"

    if [ "$FIX" = true ]; then
        color_print "$BLUE" "     正在尝试安装 hcloud CLI..."
        # 安全安装: 下载到临时文件 → 校验 → 确认 → 执行 (避免 curl|bash 远程代码执行)
        install_script=$(mktemp /tmp/hcloud_install.XXXXXX.sh) || {
            color_print "$RED" "     ❌ 创建临时文件失败"
            return 1
        }
        if curl -sSL -o "$install_script" https://hwcloudcli.obs.cn-north-4.myhuaweicloud.com/cli/latest/hcloud_install.sh 2>/dev/null; then
            # 基本校验: 文件非空且包含已知 hcloud 安装脚本标识
            if [ -s "$install_script" ] && grep -q 'hcloud' "$install_script" 2>/dev/null; then
                chmod +x "$install_script"
                if bash "$install_script" 2>/dev/null; then
                    color_print "$GREEN" "     ✅ hcloud CLI 安装成功"
                    PASS_COUNT=$((PASS_COUNT + 1))
                    FAIL_COUNT=$((FAIL_COUNT - 1))
                else
                    color_print "$RED" "     ❌ 自动安装失败，请手动安装: https://support.huaweicloud.com/cli/index.html"
                fi
            else
                color_print "$RED" "     ❌ 下载的安装脚本校验失败，请手动安装: https://support.huaweicloud.com/cli/index.html"
            fi
        else
            color_print "$RED" "     ❌ 下载安装脚本失败，请手动安装: https://support.huaweicloud.com/cli/index.html"
        fi
        rm -f "$install_script" 2>/dev/null
    else
        color_print "$BLUE" "     安装方式: https://support.huaweicloud.com/cli/index.html"
    fi
fi

# 2. jq
if command -v jq >/dev/null 2>&1; then
    check_pass "jq: $(command -v jq)"
else
    check_fail "jq 未安装"

    if [ "$FIX" = true ]; then
        color_print "$BLUE" "     正在尝试安装 jq..."
        if apt-get install -y jq >/dev/null 2>&1 || yum install -y jq >/dev/null 2>&1; then
            check_pass "jq 安装成功"
            FAIL_COUNT=$((FAIL_COUNT - 1))
        else
            color_print "$RED" "     ❌ 自动安装失败，请手动安装 jq"
        fi
    fi
fi

# 3. curl
if command -v curl >/dev/null 2>&1; then
    check_pass "curl: $(command -v curl)"
else
    check_fail "curl 未安装"

    if [ "$FIX" = true ]; then
        color_print "$BLUE" "     正在尝试安装 curl..."
        if apt-get install -y curl >/dev/null 2>&1 || yum install -y curl >/dev/null 2>&1; then
            check_pass "curl 安装成功"
            FAIL_COUNT=$((FAIL_COUNT - 1))
        else
            color_print "$RED" "     ❌ 自动安装失败，请手动安装 curl"
        fi
    fi
fi

echo ""

# 4. hcloud 认证
echo "2️⃣  认证配置"
echo "──────────────────────────────────────"

if command -v hcloud >/dev/null 2>&1; then
    # 检测认证模式
    auth_mode=$(detect_auth_mode)

    case "$auth_mode" in
        env_vars)
            check_pass "认证模式: 环境变量 (HW_ACCESS_KEY + HW_SECRET_KEY)"
            # 验证 API 可用性 — 调用 DNS ListPublicZones
            if hcloud DNS ListPublicZones --limit=1 --cli-output=json >/dev/null 2>&1; then
                check_pass "API 调用验证: DNS ListPublicZones 成功"
            else
                check_fail "API 调用验证: DNS ListPublicZones 失败（凭证可能无效或权限不足）"
            fi
            check_warn "凭证通过命令行参数传递（ps aux 可见），建议使用 hcloud configure 模式"
            ;;
        hcloud_configure)
            check_pass "认证模式: hcloud configure（凭证加密存储，不暴露到命令行）"
            # 验证 API 可用性 — 调用 DNS ListPublicZones
            if hcloud DNS ListPublicZones --limit=1 --cli-output=json >/dev/null 2>&1; then
                check_pass "API 调用验证: DNS ListPublicZones 成功"
            else
                check_fail "API 调用验证: DNS ListPublicZones 失败（凭证可能无效或权限不足）"
            fi
            ;;
        none)
            check_fail "未检测到有效认证"
            color_print "$BLUE" "   方式1: 设置环境变量"
            color_print "$BLUE" "     export HW_ACCESS_KEY=<your-ak>"
            color_print "$BLUE" "     export HW_SECRET_KEY=<your-sk>"
            color_print "$BLUE" "   方式2: 使用 hcloud configure 交互式配置（推荐）"
            color_print "$BLUE" "     运行 hcloud configure 按提示交互输入 AK/SK（请勿在命令行传入凭证参数）"
            ;;
    esac
else
    check_warn "跳过认证检查（hcloud CLI 未安装）"
fi

echo ""

# 5. 环境变量
echo "3️⃣  环境变量"
echo "──────────────────────────────────────"

if [ -n "${HW_REGION_NAME:-}" ]; then
    check_pass "HW_REGION_NAME=${HW_REGION_NAME}"
else
    check_warn "HW_REGION_NAME 未设置（将使用默认值 cn-north-4）"
fi

if [ -n "${HW_ACCESS_KEY:-}" ]; then
    check_pass "HW_ACCESS_KEY 已设置"
else
    check_warn "HW_ACCESS_KEY 未设置（若已使用 hcloud configure 则可忽略）"
fi

if [ -n "${HW_SECRET_KEY:-}" ]; then
    check_pass "HW_SECRET_KEY 已设置"
else
    check_warn "HW_SECRET_KEY 未设置（若已使用 hcloud configure 则可忽略）"
fi

if [ -n "${HW_SECURITY_TOKEN:-}" ]; then
    check_pass "HW_SECURITY_TOKEN 已设置（临时凭证模式）"
else
    if [ "$VERBOSE" = true ]; then
        check_warn "HW_SECURITY_TOKEN 未设置（仅永久 AK/SK 模式时可忽略）"
    fi
fi

echo ""

# 6. 可选依赖
echo "4️⃣  可选依赖"
echo "──────────────────────────────────────"

# dig — DNS 解析验证工具
if command -v dig >/dev/null 2>&1; then
    check_pass "dig: $(command -v dig)（DNS 记录解析验证）"
else
    check_warn "dig 未安装（DNS 记录解析验证功能不可用）"

    if [ "$FIX" = true ]; then
        color_print "$BLUE" "     正在尝试安装 dig (bind-utils/dnsutils)..."
        if apt-get install -y dnsutils >/dev/null 2>&1 || yum install -y bind-utils >/dev/null 2>&1; then
            check_pass "dig 安装成功"
            WARN_COUNT=$((WARN_COUNT - 1))
        else
            color_print "$RED" "     ❌ 自动安装失败，请手动安装 dig (apt: dnsutils, yum: bind-utils)"
        fi
    fi
fi

# nslookup — DNS 解析验证工具（备选）
if command -v nslookup >/dev/null 2>&1; then
    check_pass "nslookup: $(command -v nslookup)（DNS 记录解析验证备选）"
else
    check_warn "nslookup 未安装（DNS 记录解析验证备选功能不可用）"

    if [ "$FIX" = true ]; then
        color_print "$BLUE" "     正在尝试安装 nslookup (bind-utils/dnsutils)..."
        if apt-get install -y dnsutils >/dev/null 2>&1 || yum install -y bind-utils >/dev/null 2>&1; then
            check_pass "nslookup 安装成功"
            WARN_COUNT=$((WARN_COUNT - 1))
        else
            color_print "$RED" "     ❌ 自动安装失败，请手动安装 nslookup (apt: dnsutils, yum: bind-utils)"
        fi
    fi
fi

echo ""

# ── 总结 ──────────────────────────────────────────────────────────
echo "================================================================"
echo "📋 检查总结"
echo "================================================================"
echo "  ✅ 通过: ${PASS_COUNT}"
echo "  ❌ 失败: ${FAIL_COUNT}"
echo "  ⚠️  警告: ${WARN_COUNT}"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    color_print "$RED" "❌ 环境检查未通过，请修复上述失败项后重试"
    echo ""
    if [ "$FIX" = false ]; then
        color_print "$BLUE" "💡 提示：使用 --fix 参数可尝试自动修复部分依赖"
    fi
    exit 1
elif [ "$WARN_COUNT" -gt 0 ]; then
    color_print "$YELLOW" "⚠️  环境检查通过，但有 ${WARN_COUNT} 个警告"
    exit 0
else
    color_print "$GREEN" "✅ 环境检查全部通过！"
    exit 0
fi