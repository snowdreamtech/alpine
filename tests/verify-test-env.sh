#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.
#
# Purpose: 验证测试环境是否正确配置
# Usage: sh tests/verify-test-env.sh

set -eu

# ── Color Output ─────────────────────────────────────────────────────────────
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# ── Logging Functions ────────────────────────────────────────────────────────
log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$*"
}

log_success() {
    printf "${GREEN}[✓]${NC} %s\n" "$*"
}

log_warn() {
    printf "${YELLOW}[!]${NC} %s\n" "$*"
}

log_error() {
    printf "${RED}[✗]${NC} %s\n" "$*"
}

# ── Version Check Functions ──────────────────────────────────────────────────
check_command() {
    local cmd="${1:-}"
    # shellcheck disable=SC2034
    local min_version="${2:-}"
    local name="${3:-$cmd}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "$name: 未安装"
        return 1
    fi

    local path
    path=$(command -v "$cmd")
    log_success "$name: 已安装"
    printf "         路径: %s\n" "$path"

    # 获取版本信息
    local version=""
    case "$cmd" in
        bats)
            version=$("$cmd" --version 2>/dev/null | head -n 1 || echo "unknown")
            ;;
        node)
            version=$("$cmd" --version 2>/dev/null || echo "unknown")
            ;;
        python3)
            version=$("$cmd" --version 2>/dev/null || echo "unknown")
            ;;
        jq)
            version=$("$cmd" --version 2>/dev/null || echo "unknown")
            ;;
        timeout|gtimeout)
            version=$("$cmd" --version 2>/dev/null | head -n 1 || echo "unknown")
            ;;
    esac

    if [ -n "$version" ] && [ "$version" != "unknown" ]; then
        printf "         版本: %s\n" "$version"
    fi

    return 0
}

check_directory() {
    local dir="${1:-}"
    local desc="${2:-$dir}"

    if [ ! -d "$dir" ]; then
        log_error "$desc: 目录不存在"
        return 1
    fi

    log_success "$desc: 目录存在"
    return 0
}

# ── Main Verification ────────────────────────────────────────────────────────
main() {
    log_info "开始验证测试环境..."
    echo ""

    local errors=0

    # 检查必需工具
    log_info "=== 必需工具 ==="
    check_command "bats" "1.11.0" "BATS" || errors=$((errors + 1))
    check_command "node" "20.0.0" "Node.js" || errors=$((errors + 1))
    check_command "python3" "3.12.0" "Python" || errors=$((errors + 1))
    echo ""

    # 检查可选工具
    log_info "=== 可选工具 ==="
    if check_command "jq" "" "jq"; then
        :
    else
        log_warn "jq: 未安装（可选，用于 JSON 解析降级测试）"
    fi

    if check_command "timeout" "" "timeout"; then
        :
    elif check_command "gtimeout" "" "gtimeout"; then
        :
    else
        log_warn "timeout/gtimeout: 未安装（可选，用于超时测试）"
    fi
    echo ""

    # 检查测试目录结构
    log_info "=== 测试目录结构 ==="
    check_directory "tests" "tests/" || errors=$((errors + 1))
    check_directory "tests/unit" "tests/unit/" || errors=$((errors + 1))
    check_directory "tests/integration" "tests/integration/" || errors=$((errors + 1))
    check_directory "tests/fixtures" "tests/fixtures/" || errors=$((errors + 1))
    check_directory "tests/vendor" "tests/vendor/" || errors=$((errors + 1))
    check_directory "tests/vendor/bats-support" "tests/vendor/bats-support/" || errors=$((errors + 1))
    check_directory "tests/vendor/bats-assert" "tests/vendor/bats-assert/" || errors=$((errors + 1))
    echo ""

    # 检查 BATS 辅助库
    log_info "=== BATS 辅助库 ==="
    if [ -f "tests/vendor/bats-support/load.bash" ]; then
        log_success "bats-support: 已安装"
    else
        log_error "bats-support: 未找到 load.bash"
        errors=$((errors + 1))
    fi

    if [ -f "tests/vendor/bats-assert/load.bash" ]; then
        log_success "bats-assert: 已安装"
    else
        log_error "bats-assert: 未找到 load.bash"
        errors=$((errors + 1))
    fi
    echo ""

    # 测试 BATS 是否可以运行
    log_info "=== BATS 功能测试 ==="
    if bats --version >/dev/null 2>&1; then
        log_success "BATS 可以正常运行"
    else
        log_error "BATS 无法运行"
        errors=$((errors + 1))
    fi
    echo ""

    # 测试 Node.js 是否可以运行
    log_info "=== Node.js 功能测试 ==="
    if node -e "console.log('test')" >/dev/null 2>&1; then
        log_success "Node.js 可以正常运行"
    else
        log_error "Node.js 无法运行"
        errors=$((errors + 1))
    fi
    echo ""

    # 测试 Python 是否可以运行
    log_info "=== Python 功能测试 ==="
    if python3 -c "print('test')" >/dev/null 2>&1; then
        log_success "Python 可以正常运行"
    else
        log_error "Python 无法运行"
       errors=$((errors + 1))
    fi
    echo ""

    # 总结
    log_info "=== 验证总结 ==="
    if [ "$errors" -eq 0 ]; then
        log_success "测试环境配置完整，所有必需工具已安装"
        echo ""
        log_info "下一步操作："
        printf "  1. 运行测试: %sbats tests/**/*.bats%s\n" "${GREEN}" "${NC}"
        printf "  2. 运行单元测试: %sbats tests/unit/*.bats%s\n" "${GREEN}" "${NC}"
        printf "  3. 运行集成测试: %sbats tests/integration/*.bats%s\n" "${GREEN}" "${NC}"
        echo ""
        return 0
    else
        log_error "发现 $errors 个问题，请修复后重试"
        echo ""
        log_info "修复建议："
        printf "  1. 安装缺失工具: %smise install%s\n" "${YELLOW}" "${NC}"
        printf "  2. 创建缺失目录: %smkdir -p tests/unit tests/integration tests/fixtures%s\n" "${YELLOW}" "${NC}"
        printf "  3. 查看文档: %scat tests/README.md%s\n" "${YELLOW}" "${NC}"
        echo ""
        return 1
    fi
}

# ── Entry Point ──────────────────────────────────────────────────────────────
main "$@"
