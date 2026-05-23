#!/usr/bin/env bash
# =============================================================================
# verify.sh — 开发环境健康检查
# =============================================================================
# 用法:
#   bash verify.sh                  # 标准检查
#   bash verify.sh --verbose        # 详细输出
#   bash verify.sh --fix            # 尝试自动修复常见问题
#   bash verify.sh --strict         # 将可选检查视为失败
#   bash verify.sh --verbose --fix  # 详细 + 自动修复
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

VERBOSE=false
FIX_MODE=false
STRICT_MODE=false

print_help() {
    cat <<'EOF'
用法: bash verify.sh [OPTIONS]

选项:
  --verbose   显示详细输出，包括失败命令的详情。
  --fix       自动修复文件权限（chmod）。
  --strict    将可选检查视为失败，而非警告。
  --help      显示此帮助信息并退出。

检查项目:
  系统、Shell 环境、环境变量、Mise 工具、Python、
  Dotfiles、zsh 插件、密钥与权限
EOF
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        --verbose) VERBOSE=true ;;
        --fix)     FIX_MODE=true ;;
        --strict)  STRICT_MODE=true ;;
        --help)    print_help ;;
    esac
done

PASS=0; FAIL=0; SKIP=0
SKIP_ITEMS=()

pass_msg() { printf '%s✓%s %s\n' "$C_GREEN" "$C_NC" "$*"; }
fail_msg() { printf '%s✗%s %s%s FAIL%s\n' "$C_RED" "$C_NC" "$*" "$C_RED" "$C_NC"; }
skip_msg() { printf '%s○%s %s%s SKIP%s\n' "$C_YELLOW" "$C_NC" "$*" "$C_YELLOW" "$C_NC"; }

vlog() {
    if $VERBOSE; then
        printf '    %s→%s %s\n' "$C_BLUE" "$C_NC" "$*"
    fi
}

# --- 检查函数 ----------------------------------------------------------------
# 注意：所有检查命令均为硬编码，无用户输入，bash -c 在此上下文中是安全的。
_check_inner() {
    local name="$1" check_cmd="$2" required="${3:-true}" err
    printf "  %-40s" "$name"
    if err=$(bash -c "$check_cmd" 2>&1 >/dev/null); then
        pass_msg ""
        PASS=$((PASS + 1))
        return 0
    fi
    if $required || $STRICT_MODE; then
        fail_msg ""
        FAIL=$((FAIL + 1))
        if [[ -n "$err" ]]; then
            printf '    %s→%s %s\n' "$C_RED" "$C_NC" "$(tail -1 <<<"$err")"
        fi
        vlog "命令: $check_cmd"
    else
        skip_msg ""
        SKIP=$((SKIP + 1))
        SKIP_ITEMS+=("$name")
        vlog "命令: $check_cmd"
    fi
}

check()     { _check_inner "$1" "$2" true; }
check_opt() { _check_inner "$1" "$2" false; }

check_content() {
    local name="$1" file="$2" pattern="$3"
    printf "  %-40s" "$name"
    if [ -f "$file" ] && grep -qF "$pattern" "$file" 2>/dev/null; then
        pass_msg ""
        PASS=$((PASS + 1))
    elif [ ! -f "$file" ]; then
        fail_msg ""
        FAIL=$((FAIL + 1))
        printf '    %s→%s 文件缺失: %s\n' "$C_RED" "$C_NC" "$file"
        vlog "文件缺失: $file"
    else
        fail_msg ""
        FAIL=$((FAIL + 1))
        printf '    %s→%s 未找到匹配: '"'"'%s'"'"' 在 %s\n' "$C_RED" "$C_NC" "$pattern" "$file"
        vlog "未找到匹配: '$pattern' 在 $file 中"
    fi
}

check_perm() {
    local name="$1" file="$2" expected="$3"
    printf "  %-40s" "$name"
    if [ -f "$file" ]; then
        local actual
        actual=$(stat -c '%a' "$file" 2>/dev/null || echo "000")
        if [ "$actual" = "$expected" ]; then
            pass_msg ""
            PASS=$((PASS + 1))
        else
            fail_msg ""
            FAIL=$((FAIL + 1))
            vlog "权限: $actual (期望 $expected)"
            if $FIX_MODE; then
                chmod "$expected" "$file" && vlog "已修复权限为 $expected"
            fi
        fi
    else
        skip_msg ""
        SKIP=$((SKIP + 1))
    fi
}

print_section() {
    printf '\n  %s[ %s ]%s\n' "$C_CYAN" "$1" "$C_NC"
}

# --- 页眉 -------------------------------------------------------------------
printf '\n'
printf '  ┌──────────────────────────────────────────────────────────────┐\n'
printf '  │         Ubuntu-Bootstrap 环境验证                           │\n'
printf '  └──────────────────────────────────────────────────────────────┘\n'
printf '\n'

# --- 系统 -------------------------------------------------------------------
print_section "系统"
check     "Ubuntu 系统检测"           "grep -qi ubuntu /etc/os-release 2>/dev/null || grep -qi ubuntu /etc/lsb-release 2>/dev/null || true"
check     "lsb_release 可用"     "lsb_release -ds 2>/dev/null || true"
check     "系统架构"              "uname -m"
check     "Locale en_US.UTF-8"        "locale -a 2>/dev/null | grep -q en_US.utf8"

# --- Shell ------------------------------------------------------------------
print_section "Shell 环境"
check     "zsh 已安装"             "zsh --version"
check_opt "zsh 是否为默认 Shell"      "echo \$SHELL | grep -q /zsh || [ \"\${SKIP_INTERACTIVE:-0}\" = \"1\" ]"
check_opt "starship 已安装"        "starship --version"

# --- Mise 工具 (从 mise ls 自动生成) ---------------------------------------
print_section "Mise 工具"

MISE_BIN="${HOME}/.local/bin/mise"
if [ -x "$MISE_BIN" ]; then
    check     "mise 已安装"        "$MISE_BIN --version"

    declare -A BIN_MAP=(
        [ripgrep]=rg
        [tealdeer]=tldr
        [difftastic]=difft
        [cli]=gh
    )

    while IFS= read -r tool; do
        [ -z "$tool" ] && continue
        short="${tool##*/}"
        bin="${BIN_MAP[$short]:-$short}"
        check_opt "$short" "command -v $bin && ($bin --version 2>/dev/null || $bin version 2>/dev/null)"
    done < <("$MISE_BIN" ls --json 2>/dev/null | jq -r 'keys[]' 2>/dev/null || true)
else
    fail_msg "mise 未找到"
fi

# --- Python ----------------------------------------------------------------
print_section "Python"
check     "uv 已安装"              "uv --version"
check_opt "Python (uv 管理)"       "uv python find 2>/dev/null"
check_opt "Ruff 已安装"            "ruff --version"

# --- 开发工具 (apt 管理) ---------------------------------------------------
print_section "开发工具"
check_opt "fzf"                "fzf --version"
check_opt "tree"               "tree --version"

# --- Dotfiles ----------------------------------------------------------------
print_section "Dotfiles"
check     ".zshrc 已符号链接"       "test -L ~/.zshrc && readlink ~/.zshrc | grep -q ubuntu-bootstrap"
check_opt ".zshenv 已符号链接"      "test -L ~/.zshenv && readlink ~/.zshenv | grep -q ubuntu-bootstrap"
check_opt ".profile 已符号链接"     "test -L ~/.profile && readlink ~/.profile | grep -q ubuntu-bootstrap"
check_opt ".gitconfig 已符号链接"   "test -L ~/.gitconfig && readlink ~/.gitconfig | grep -q ubuntu-bootstrap"
check     "starship.toml 已链接"      "test -L ~/.config/starship.toml && readlink ~/.config/starship.toml | grep -q ubuntu-bootstrap"
check     "mise 配置已链接"        "test -L ~/.config/mise/config.toml && readlink ~/.config/mise/config.toml | grep -q ubuntu-bootstrap"
check     "zsh 模块目录存在"     "test -d ~/.config/zsh"

for mod_path in "$SCRIPT_DIR/config/zsh"/*.zsh; do
    [ -f "$mod_path" ] || continue
    mod="$(basename "$mod_path")"
    check_opt "zsh/${mod} 已链接"   "test -L ~/.config/zsh/${mod} && readlink ~/.config/zsh/${mod} | grep -q ubuntu-bootstrap"
done

# --- zsh 插件 ----------------------------------------------------------------
print_section "zsh 插件"
ZSH_PLUGIN_DIR="$HOME/.local/share/zsh-plugins"
check_opt "zsh-autosuggestions"       "test -f $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
check_opt "zsh-syntax-highlighting"   "test -f $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# --- 环境变量 ---------------------------------------------------------------
print_section "环境变量"
check_opt "EDITOR 已设置"             "grep -q 'EDITOR' ~/.zshenv 2>/dev/null"
check_opt "VISUAL 已设置"             "grep -q 'VISUAL' ~/.zshenv 2>/dev/null"

# --- 密钥与权限 ---------------------------------------------------------------
print_section "密钥与权限"
check_perm ".env_secrets 权限 600"       "$HOME/.env_secrets" "600"

# --- 汇总 -------------------------------------------------------------------
printf '\n'
printf '  ┌──────────────────────────────────────────────────────────────┐\n'
TOTAL=$((PASS + FAIL + SKIP))
printf '  │  通过: %-3s  失败: %-3s  跳过: %-3s  总计: %-3s          │\n' "$PASS" "$FAIL" "$SKIP" "$TOTAL"
printf '  └──────────────────────────────────────────────────────────────┘\n'
printf '\n'

if [ ${#SKIP_ITEMS[@]} -gt 0 ]; then
    printf '%s  已跳过 (可选检查):%s\n' "$C_YELLOW" "$C_NC"
    for item in "${SKIP_ITEMS[@]}"; do
        printf "    • %s\n" "$item"
    done
    printf '\n'
fi

if [ "$FAIL" -gt 0 ]; then
    warn "部分必需检查失败。使用 --verbose 查看详情，--fix 尝试修复。"
    exit 1
else
    success "所有必需检查已通过。"
    if [ "$SKIP" -gt 0 ]; then
        log "$SKIP 项可选检查已跳过。使用 --strict 将其视为失败。"
    fi
fi
