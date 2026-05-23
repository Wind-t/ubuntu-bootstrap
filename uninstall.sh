#!/usr/bin/env bash
# =============================================================================
# uninstall.sh — 移除 ubuntu-bootstrap 管理的文件
# =============================================================================
# 用法:
#   bash uninstall.sh              # 交互模式（破坏性操作前询问）
#   bash uninstall.sh --yes        # 非交互模式，自动确认所有提示
#   bash uninstall.sh --all        # 同时移除 ~/.local/bin（交互模式）
#   bash uninstall.sh --all --yes  # 完全清理，无提示
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ALL_MODE=false
YES_MODE=false

print_help() {
    cat <<'EOF'
用法: bash uninstall.sh [OPTIONS]

选项:
  --all    同时移除 ~/.local/bin 中的二进制文件（需要确认）。
  --yes    跳过所有确认提示（非交互模式）。
  --help   显示此帮助信息并退出。

示例:
  bash uninstall.sh
  bash uninstall.sh --all
  bash uninstall.sh --all --yes
EOF
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        --all)  ALL_MODE=true ;;
        --yes)  YES_MODE=true ;;
        --help) print_help ;;
    esac
done

# ubuntu-bootstrap 管理的 dotfiles — 由 common.sh 中的 UB_DOTFILE_DESTS 集中定义
ZSH_MODULE_DIR="$HOME/.config/zsh"

confirm() {
    if $YES_MODE; then
        return 0
    fi
    local prompt="$1"
    local default="${2:-N}"
    read -rp "  $prompt [$default] " yn
    if [ "$default" = "yes" ]; then
        # Require literal "yes" for destructive operations
        [[ "$yn" =~ ^[Yy][Ee][Ss]$ ]]
    elif [ "$default" = "N" ]; then
        [[ "$yn" =~ ^[Yy]$ ]]
    else
        [[ "$yn" =~ ^[Yy]$ ]] || [ -z "$yn" ]
    fi
}

section "ubuntu-bootstrap 卸载"

# --- 第 1 步: 解除 dotfile 符号链接 -------------------------------------------
log "正在解除 dotfile 符号链接..."
COUNT=0

# 优先使用 manifest（运行时记录，最准确）。
# 若 manifest 不存在，回退到 UB_DOTFILE_DESTS（编译时定义）。
if [ -f "$UB_MANIFEST" ]; then
    while IFS=$'\t' read -r dst src; do
        [ -z "$dst" ] && continue
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            rm "$dst"
            success "已删除: $dst"
            COUNT=$((COUNT + 1))
        elif [ -f "$dst" ]; then
            warn "跳过 (普通文件，非符号链接): $dst"
        fi
    done < "$UB_MANIFEST"
    rm -f "$UB_MANIFEST"
else
    # Fallback: compile-time dotfile list
    for dst in "${UB_DOTFILE_DESTS[@]}"; do
        if [ -L "$dst" ]; then
            target=$(readlink "$dst")
            if [[ "$target" == "$SCRIPT_DIR/"* ]]; then
                rm "$dst"
                success "已删除: $dst"
                COUNT=$((COUNT + 1))
            else
                warn "跳过 (非 ubuntu-bootstrap): $dst → $target"
            fi
        elif [ -f "$dst" ]; then
            warn "跳过 (普通文件，非符号链接): $dst"
        fi
    done

    # zsh 模块
    if [ -d "$ZSH_MODULE_DIR" ]; then
        for f in "$ZSH_MODULE_DIR"/*.zsh; do
            if [ -L "$f" ]; then
                target=$(readlink "$f")
                if [[ "$target" == "$SCRIPT_DIR/"* ]]; then
                    rm "$f"
                    success "已删除: $f"
                    COUNT=$((COUNT + 1))
                fi
            fi
        done
    fi
fi
log "已解除 $COUNT 个 dotfile 符号链接。"

# --- 第 2 步: 清理 oh-my-zsh 残留 ------------------------------------------
if [ -d "$HOME/.oh-my-zsh" ]; then
    log "发现 ~/.oh-my-zsh（旧版 ubuntu-bootstrap 残留，可能冲突）。"
    if confirm "移除 ~/.oh-my-zsh? [y/N]"; then
        rm -rf "$HOME/.oh-my-zsh"
        success "已删除 ~/.oh-my-zsh"
    else
        log "保留 ~/.oh-my-zsh"
    fi
fi

# --- 第 3 步: 移除 ~/.local/bin 二进制文件（仅 --all） -------------------
if $ALL_MODE; then
    if [ -d "$HOME/.local/bin" ] && [ -n "$(ls -A "$HOME/.local/bin" 2>/dev/null)" ]; then
        ls -1 "$HOME/.local/bin" 2>/dev/null | sed 's/^/    /' || true
        warn "这将移除 ~/.local/bin 中的所有二进制文件。"
        log "其中部分可能并非 ubuntu-bootstrap 安装。"
        if confirm "确认操作? 输入 'yes' 确认:" "yes"; then
            rm -rf "$HOME/.local/bin"/*
            success "已清空 ~/.local/bin"
        else
            log "保留 ~/.local/bin"
        fi
    else
        log "$HOME/.local/bin 为空或不存在。"
    fi
else
    log "(使用 --all 同时移除 ~/.local/bin 中的二进制文件)"
fi

# --- 第 4 步: 移除 zsh 插件 ------------------------------------------------
ZSH_PLUGIN_DIR="$HOME/.local/share/zsh-plugins"
if [ -d "$ZSH_PLUGIN_DIR" ]; then
    log "发现 zsh 插件目录: $ZSH_PLUGIN_DIR"
    if confirm "移除 $ZSH_PLUGIN_DIR? [y/N]"; then
        rm -rf "$ZSH_PLUGIN_DIR"
        success "已删除 $ZSH_PLUGIN_DIR"
    else
        log "保留 $ZSH_PLUGIN_DIR"
    fi
fi

# --- 第 5 步: 移除缓存 -------------------------------------------------------
if [ -f "$HOME/.cache/mise-activate.zsh" ]; then
    rm "$HOME/.cache/mise-activate.zsh"
    success "已删除 mise 激活缓存"
fi
if [ -d "$HOME/.cache/zsh" ]; then
    rm -rf "$HOME/.cache/zsh"
    success "已删除 zsh 补全缓存"
fi

# --- 完成 -------------------------------------------------------------------
section "卸载完成"

log "可选手动清理:"
log "  rm -rf ~/.local/share/mise   (mise 安装文件)"
log "  rm -rf ~/.local/share/uv     (uv 安装文件)"
log "  rm -rf ~/.cache              (工具缓存)"
log "  sudo apt remove <packages>   (apt 软件包)"
