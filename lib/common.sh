#!/usr/bin/env bash
# =============================================================================
# lib/common.sh — ubuntu-bootstrap 脚本通用辅助函数
# =============================================================================

# --- 颜色常量 -----------------------------------------------------------------
# 尊重 NO_COLOR 标准 (https://no-color.org)，非 TTY 输出也自动关闭颜色
if [ -n "${NO_COLOR:-}" ] || [ ! -t 1 ]; then
    C_GREEN='' C_RED='' C_YELLOW='' C_CYAN='' C_BLUE='' C_NC=''
    declare -r C_GREEN C_RED C_YELLOW C_CYAN C_BLUE C_NC
else
    declare -r C_GREEN='\033[1;32m'
    declare -r C_RED='\033[1;31m'
    declare -r C_YELLOW='\033[1;33m'
    declare -r C_CYAN='\033[1;36m'
    declare -r C_BLUE='\033[1;34m'
    declare -r C_NC='\033[0m'
fi

# --- 日志级别 ---------------------------------------------------------------
QUIET="${QUIET:-0}"

log()     { [ "$QUIET" = "1" ] || printf '%s[INFO]%s  %s\n' "$C_BLUE" "$C_NC" "$*"; }
success() { printf '%s[OK]%s    %s\n' "$C_GREEN" "$C_NC" "$*"; }
warn()    { printf '%s[WARN]%s  %s\n' "$C_YELLOW" "$C_NC" "$*"; }
fail()    { printf '%s[FAIL]%s  %s\n' "$C_RED" "$C_NC" "$*"; exit 1; }
die()     { printf '%s[FATAL]%s %s\n' "$C_RED" "$C_NC" "$*" >&2; exit "${2:-1}"; }

section() {
    local msg
    msg=$(printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n  %s\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' "$*")
    [ "$QUIET" = "1" ] || printf '\n%s%s%s\n' "$C_CYAN" "$msg" "$C_NC"
}

# --- 警告追踪 ---------------------------------------------------------------
# 累积非致命警告，在结束时统一报告，不打断安装流程。
declare -ga _WARNINGS=()

warn_track() {
    _WARNINGS+=("$*")
}

print_warnings_summary() {
    if [ ${#_WARNINGS[@]} -eq 0 ]; then
        return 0
    fi
    printf '\n'
    printf '%s━━━ %d 条警告（建议复查）━━━%s\n' "$C_YELLOW" "${#_WARNINGS[@]}" "$C_NC"
    local w
    for w in "${_WARNINGS[@]}"; do
        printf '  %s•%s %s\n' "$C_YELLOW" "$C_NC" "$w"
    done
    printf '\n'
}

# --- 错误捕获 ----------------------------------------------------------------
# 追踪当前部署步骤，以便定位出错位置。
BOOTSTRAP_STEP="initializing"

set_step() { BOOTSTRAP_STEP="$*"; }

BOOTSTRAP_START=$(date +%s)

bootstrap_trap() {
    local exit_code=$?
    local elapsed=$(( $(date +%s) - BOOTSTRAP_START ))
    if [ "$exit_code" -ne 0 ]; then
        printf '\n'
        print_warnings_summary
        printf '%s[FAIL]%s  部署在步骤 %s 失败（退出码：%s，耗时 %ds）\n' "$C_RED" "$C_NC" "$BOOTSTRAP_STEP" "$exit_code" "$elapsed"
        log "运行 'bash verify.sh' 检查当前状态。"
        log "重新运行 bootstrap.sh 是安全的 — 脚本是幂等的。"
        exit "$exit_code"
    fi
    print_warnings_summary
}

interrupt_handler() {
    local elapsed=$(( $(date +%s) - BOOTSTRAP_START ))
    printf '\n%s[WARN]%s 用户中断（耗时 %ds）。部分工具可能已安装。\n' "$C_YELLOW" "$C_NC" "$elapsed"
    exit 130
}

# --- 文件系统 ----------------------------------------------------------------
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || die "创建目录失败：$dir"
    fi
}

# 将 ~/.local/bin 添加到 PATH 头部（幂等，只添加一次）
_ensure_local_bin_path() {
    case ":$PATH:" in
        *:"$HOME/.local/bin":*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
}

backup_then_link() {
    local src="$1"
    local dst="$2"
    if [ ! -f "$src" ]; then
        warn_track "源文件不存在，跳过：$src"
        return 0
    fi
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        log "已链接：$dst"
        return 0
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        local bak
        bak="${dst}.bak.$(date +%s)"
        log "备份现有文件：$dst → $bak"
        mv "$dst" "$bak"
    fi
    ensure_dir "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    success "已链接：$dst → $src"
}

# --- Dotfile destinations (single source of truth) ----------------------------
# Used by setup-dotfiles.sh and uninstall.sh. Update HERE when adding dotfiles.
UB_DOTFILE_DESTS=(
    "$HOME/.zshrc"
    "$HOME/.zshenv"
    "$HOME/.profile"
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"
    "$HOME/.config/starship.toml"
    "$HOME/.config/mise/config.toml"
)
export UB_DOTFILE_DESTS

# --- 二进制下载 + SHA256 校验 -----------------------------------------------
# 从 GitHub Release 下载二进制包，校验 SHA256，返回已验证的临时文件路径。
# parse_cmd 通过 stdin 读取 SHA 校验文件内容，输出期望的哈希值。
# 用法: _fetch_verified <label> <bin_url> <sha_url> <parse_cmd> <out_var>
_fetch_verified() {
    local label="$1" bin_url="$2" sha_url="$3" parse_cmd="$4" out_var="$5"
    local bin_file sha_file expected actual

    bin_file="$(mktemp)" || fail "无法创建临时文件"
    sha_file="$(mktemp)" || { rm -f "$bin_file"; fail "无法创建临时文件"; }

    if ! curl --proto '=https' --tlsv1.2 -fsSL --retry 3 --retry-all-errors "$sha_url" -o "$sha_file"; then
        rm -f "$bin_file" "$sha_file"
        fail "无法下载 ${label} SHA256 校验文件（${sha_url}）"
    fi
    if ! curl --proto '=https' --tlsv1.2 -fsSL --retry 3 --retry-all-errors "$bin_url" -o "$bin_file"; then
        rm -f "$bin_file" "$sha_file"
        fail "无法下载 ${label} 二进制文件（${bin_url}）"
    fi

    # parse_cmd MUST be a literal/static string (e.g. 'awk "{print \$1}"').
    # Never construct parse_cmd from external input — eval is the caller.
    expected="$(eval "$parse_cmd" < "$sha_file")"
    if [ -z "$expected" ]; then
        rm -f "$bin_file" "$sha_file"
        fail "SHA256 校验文件中未找到 ${label} 的校验值"
    fi
    actual="$(sha256sum "$bin_file" | awk '{print $1}')"
    if [ "$expected" != "$actual" ]; then
        rm -f "$bin_file" "$sha_file"
        fail "${label} SHA256 校验失败！\n  期望: $expected\n  实际: $actual\n  这可能是下载损坏或供应链攻击，安装已中止。"
    fi

    rm -f "$sha_file"
    eval "$out_var=\"$bin_file\""
}

# --- 兜底版本（集中管理）----------------------------------------------------
# 当 GitHub API 不可用时使用。CI 自动检查是否过期。
# 保持与最新 release 差距在 30 天内。
UB_MISE_FALLBACK="2026.5.14"
UB_UV_FALLBACK="0.11.16"
export UB_MISE_FALLBACK UB_UV_FALLBACK

# --- 平台检测 ---------------------------------------------------------------
is_ci()               { [ "${CI:-}" = "true" ]; }
is_interactive_skip() { [ "${SKIP_INTERACTIVE:-0}" = "1" ]; }
is_wsl()              { grep -qi microsoft /proc/version 2>/dev/null; }

# --- Dotfile Manifest --------------------------------------------------------
# 运行时记录所有符号链接，卸载时按记录清理，消除安装/卸载逻辑不同步的风险。
UB_MANIFEST_DIR="${HOME}/.local/share/ubuntu-bootstrap"
UB_MANIFEST="${UB_MANIFEST_DIR}/manifest"

_manifest_add() {
    local src="$1" dst="$2"
    ensure_dir "$UB_MANIFEST_DIR"
    # Dedup: skip if this exact entry already exists (safe to re-run)
    if [ -f "$UB_MANIFEST" ] && grep -qxF "${dst}"$'\t'"${src}" "$UB_MANIFEST" 2>/dev/null; then
        return 0
    fi
    printf '%s\t%s\n' "$dst" "$src" >> "$UB_MANIFEST"
}

_manifest_remove_all() {
    if [ ! -f "$UB_MANIFEST" ]; then
        return 0
    fi
    local count=0
    while IFS=$'\t' read -r dst src; do
        [ -z "$dst" ] && continue
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            rm "$dst" && count=$((count + 1))
        fi
    done < "$UB_MANIFEST"
    rm -f "$UB_MANIFEST"
    return "$count"
}
