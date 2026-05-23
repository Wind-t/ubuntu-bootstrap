#!/usr/bin/env bash
# =============================================================================
# lib/setup-locale.sh — locale 生成 + 默认 Shell (ubuntu-bootstrap)
# =============================================================================
set -euo pipefail

setup_locale() {
    set_step "locale + default shell"
    section "Locale 与 Shell"

    log "正在检查 locale en_US.UTF-8..."
    if locale -a 2>/dev/null | grep -q 'en_US.utf8'; then
        log "locale en_US.UTF-8 已生成。"
    else
        log "正在生成 locale en_US.UTF-8..."
        if sudo locale-gen en_US.UTF-8 > /dev/null 2>&1; then
            success "locale 已生成。"
        else
            warn_track "locale-gen 失败 — en_US.UTF-8 可能不可用。"
        fi
    fi

    if sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 2>/dev/null; then
        log "locale 配置已更新。"
    else
        warn_track "update-locale 失败（在容器中常见 — 如 locale 已设置则无害）。"
    fi

    local zsh_path
    zsh_path="$(command -v zsh)" || true
    if [ -n "$zsh_path" ] && [ "$SHELL" != "$zsh_path" ]; then
        if is_ci; then
            log "CI/Docker 环境 — 跳过 chsh。"
        elif is_interactive_skip; then
            log "SKIP_INTERACTIVE=1 — 跳过 chsh。"
        else
            # chsh 在原生 Ubuntu 上有正确的用户权限时正常工作。
            log "正在将 zsh 设为默认 Shell..."
            if sudo chsh -s "$zsh_path" "$(whoami)" </dev/null 2>/dev/null; then
                success "默认 Shell 已设置为 zsh。"
            else
                warn_track "chsh 失败 — 你可能需要手动设置 zsh。"
            fi
        fi
    else
        log "zsh 已是默认 Shell。"
    fi

    success "Locale 与 Shell 配置完成。"
}
