#!/usr/bin/env bash
# =============================================================================
# lib/setup-zsh-plugins.sh — zsh 插件管理 (ubuntu-bootstrap)
# =============================================================================
set -euo pipefail

setup_zsh_plugins() {
    set_step "zsh plugins"
    section "zsh 插件"

    local ZSH_PLUGIN_DIR="$HOME/.local/share/zsh-plugins"
    ensure_dir "$ZSH_PLUGIN_DIR"

    local name
    for repo in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting; do
        name=$(basename "$repo")
        if [ -d "$ZSH_PLUGIN_DIR/$name" ]; then
            log "正在更新 $name..."
            if git -C "$ZSH_PLUGIN_DIR/$name" pull --ff-only 2>/dev/null; then
                log "  $name 已更新。"
            else
                warn_track "$name 更新失败（网络问题？）— 使用现有副本。"
            fi
        else
            log "正在克隆 $name..."
            if git clone --depth 1 "https://github.com/$repo" "$ZSH_PLUGIN_DIR/$name" 2>/dev/null; then
                success "  $name 已克隆。"
            else
                warn_track "克隆 $name 失败（网络问题？）"
            fi
        fi
    done

    success "zsh 插件配置完成。"
}
