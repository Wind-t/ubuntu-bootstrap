#!/usr/bin/env bash
# =============================================================================
# ubuntu-bootstrap — Ubuntu 开发环境一键部署
# =============================================================================
# 幂等 — 可安全重复运行。
# 用法：
#   bash bootstrap.sh
#   bash bootstrap.sh --help
#   bash bootstrap.sh --dry-run
#   bash bootstrap.sh --skip=dotfiles,zsh-plugins
#   SKIP_INTERACTIVE=1 bash bootstrap.sh     # CI/Docker
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# --- CLI 参数解析 ------------------------------------------------------------
DRY_RUN=false
SKIP_MODULES=""

print_help() {
    cat <<'EOF'
用法: bash bootstrap.sh [OPTIONS]

选项:
  --help        显示此帮助信息并退出。
  --version     显示版本号并退出。
  --dry-run     仅显示将要执行的操作，不实际执行。
  --skip=LIST   跳过指定模块（逗号分隔）。
                可用: apt, locale, mise, uv, zsh-plugins, dotfiles

环境变量:
  SKIP_INTERACTIVE=1   跳过交互式操作（chsh），CI/Docker 用
  QUIET=1              只显示警告和错误
  NO_COLOR=1           禁用颜色输出

示例:
  bash bootstrap.sh                              # 完整部署
  bash bootstrap.sh --dry-run                    # 预览
  bash bootstrap.sh --skip=dotfiles              # 跳过 dotfiles 模块
  bash bootstrap.sh --skip=mise,uv,zsh-plugins   # 跳过多个模块
EOF
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        --help)    print_help ;;
        --version) cat "$SCRIPT_DIR/VERSION" 2>/dev/null || printf '%s\n' 'dev'; exit 0 ;;
        --dry-run) DRY_RUN=true ;;
        --skip=*)  SKIP_MODULES="${arg#--skip=}"; SKIP_MODULES="${SKIP_MODULES//[$' \t']/}" ;;
        *)         warn "未知选项: $arg（使用 --help 查看用法）"; exit 2 ;;
    esac
done

# --- Ubuntu 版本检查 ---------------------------------------------------------
if grep -qi 'ubuntu' /etc/os-release 2>/dev/null; then
    _ubuntu_ver="$(grep -oP 'VERSION_ID="\K[0-9]+' /etc/os-release 2>/dev/null || echo "0")"
    if [ "${_ubuntu_ver:-0}" -lt 22 ] 2>/dev/null; then
        warn "Ubuntu ${_ubuntu_ver}.04 版本过旧，建议升级到 Ubuntu 22.04 / 24.04 / 26.04 或更高版本。"
    fi
else
    warn "非 Ubuntu 系统 — 此脚本专为 Ubuntu 设计，可能无法正常工作。"
fi

# --- WSL 检测 -----------------------------------------------------------------
if is_wsl; then
    log "检测到 WSL 环境，将跳过 chsh 等不适用的操作。"
    if [[ "$SCRIPT_DIR" == /mnt/* ]]; then
        warn "仓库位于 Windows 分区 ($SCRIPT_DIR)，符号链接可能失败。"
        warn "建议将仓库克隆到 WSL Linux 分区：cp -r $SCRIPT_DIR ~/ubuntu-bootstrap && cd ~/ubuntu-bootstrap"
    fi
fi

trap bootstrap_trap EXIT
trap interrupt_handler INT TERM

section "ubuntu-bootstrap"
log "版本: $(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo 'dev')"
if $DRY_RUN; then
    log "[DRY-RUN] 仅预览，不执行实际操作。"
    printf '\n'
fi

source "$SCRIPT_DIR/lib/setup-apt.sh"
source "$SCRIPT_DIR/lib/setup-locale.sh"
source "$SCRIPT_DIR/lib/setup-mise.sh"
source "$SCRIPT_DIR/lib/setup-uv.sh"
source "$SCRIPT_DIR/lib/setup-zsh-plugins.sh"
source "$SCRIPT_DIR/lib/setup-dotfiles.sh"

# --- 模块执行 ----------------------------------------------------------------
in_skip() { [[ ",${SKIP_MODULES}," == *",$1,"* ]]; }

run_module() {
    local name="$1"
    shift
    if in_skip "$name"; then
        log "跳过模块: $name"
        return 0
    fi
    if $DRY_RUN; then
        log "[DRY-RUN] $name"
        return 0
    fi
    "$@"
}

run_module "apt"          setup_apt
run_module "locale"       setup_locale
run_module "mise"         setup_mise
run_module "uv"           setup_uv
run_module "zsh-plugins"  setup_zsh_plugins
run_module "dotfiles"     setup_dotfiles

# --- 完成 -------------------------------------------------------------------
if ! $DRY_RUN; then
    elapsed=$(( $(date +%s) - BOOTSTRAP_START )) 
    section "部署完成"
    printf '\n'
    log "全部部署完成（耗时 ${elapsed}s）。"
    log "接下来的步骤："
    log "  1. 重启终端或运行：exec zsh"
    if is_wsl; then
        log "     (WSL: 在 ~/.bashrc 末尾添加 exec zsh 可自动启动 zsh)"
    fi
    log "  2. 验证环境：           bash $SCRIPT_DIR/verify.sh"
    log "  3. (可选) OpenCode 设置：opencode auth login"
    printf '\n'
else
    printf '\n'
    log "[DRY-RUN] 预览完成 — 未执行任何实际操作。"
    printf '\n'
fi
