#!/usr/bin/env bash
# =============================================================================
# lib/setup-mise.sh — mise 版本管理器 + 开发工具 (ubuntu-bootstrap)
# =============================================================================
set -euo pipefail

# SCRIPT_DIR is set by bootstrap.sh before sourcing this module.
# Guard: fallback for standalone sourcing (e.g. debugging).
: "${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

setup_mise() {
    set_step "mise install + tools"
    section "mise：版本管理器与开发工具"

    if command -v mise &>/dev/null; then
        log "mise 已安装：$(mise --version 2>/dev/null)"
    else
        log "正在安装 mise（直下二进制，校验 SHA256）..."

        # 从 GitHub API 获取最新版本，失败则用兜底版本
        local mise_ver
        mise_ver="$(curl --proto '=https' --tlsv1.2 -fsSL --retry 2 \
            "https://api.github.com/repos/jdx/mise/releases/latest" 2>/dev/null \
            | grep -oP '"tag_name":\s*"\K[^"]+' || true)"
        mise_ver="${mise_ver:-v${UB_MISE_FALLBACK}}"
        local ver_no_v="${mise_ver#v}"

        local bin_url sha_url tar_name
        tar_name="mise-${mise_ver}-linux-x64.tar.xz"
        bin_url="https://github.com/jdx/mise/releases/download/${mise_ver}/${tar_name}"
        sha_url="https://github.com/jdx/mise/releases/download/${mise_ver}/SHASUMS256.txt"

        local mise_tarball
        _fetch_verified "mise" "$bin_url" "$sha_url" \
            "grep -F './${tar_name}' | awk '{print \$1}'" \
            mise_tarball

        ensure_dir "$HOME/.local/bin"
        local tmp_dir
        tmp_dir="$(mktemp -d)" || { rm -f "$mise_tarball"; fail "无法创建临时目录"; }
        if ! tar -xJf "$mise_tarball" -C "$tmp_dir" 2>/dev/null; then
            rm -rf "$tmp_dir" "$mise_tarball"
            fail "mise 解压失败"
        fi
        cp "$tmp_dir/mise/bin/mise" "$HOME/.local/bin/mise"
        chmod +x "$HOME/.local/bin/mise"
        rm -rf "$tmp_dir" "$mise_tarball"

        success "mise ${ver_no_v} 安装完成（SHA256 校验通过）。"
    fi

    export PATH="$HOME/.local/bin:$PATH"

    backup_then_link "$SCRIPT_DIR/config/mise.config.toml" "$HOME/.config/mise/config.toml"
    _manifest_add "$SCRIPT_DIR/config/mise.config.toml" "$HOME/.config/mise/config.toml"

    local tool_count
    tool_count=$(grep -cE '^\s*"[^"]+"\s*=' "$SCRIPT_DIR/config/mise.config.toml" 2>/dev/null || printf '%s' '?')
    log "正在通过 mise 安装 ${tool_count} 个工具..."
    if mise install; then
        success "mise 工具链安装完成：$(mise --version 2>/dev/null)"
    else
        fail "mise install 失败 — 开发工具未安装。请检查网络后重试。"
    fi
}
