#!/usr/bin/env bash
# =============================================================================
# lib/setup-uv.sh — uv Python 工具链 (ubuntu-bootstrap)
# =============================================================================
set -euo pipefail

setup_uv() {
    set_step "uv + Python"
    section "uv：Python 工具链"

    if command -v uv &>/dev/null; then
        log "uv 已安装：$(uv --version 2>/dev/null)"
    else
        log "正在安装 uv（直下二进制，校验 SHA256）..."

        # 从 GitHub API 获取最新版本，失败则用兜底版本
        local uv_ver
        uv_ver="$(curl --proto '=https' --tlsv1.2 -fsSL --retry 2 \
            "https://api.github.com/repos/astral-sh/uv/releases/latest" 2>/dev/null \
            | grep -oP '"tag_name":\s*"\K[^"]+' || true)"
        uv_ver="${uv_ver:-${UB_UV_FALLBACK}}"

        local arch bin_url sha_url
        arch="x86_64-unknown-linux-gnu"
        bin_url="https://github.com/astral-sh/uv/releases/download/${uv_ver}/uv-${arch}.tar.gz"
        sha_url="https://github.com/astral-sh/uv/releases/download/${uv_ver}/uv-${arch}.tar.gz.sha256"

        local uv_tarball
        _fetch_verified "uv" "$bin_url" "$sha_url" \
            "awk '{print \$1}'" \
            uv_tarball

        local tmp_dir
        tmp_dir="$(mktemp -d)" || { rm -f "$uv_tarball"; fail "无法创建临时目录"; }
        if ! tar -xzf "$uv_tarball" -C "$tmp_dir" 2>/dev/null; then
            rm -rf "$tmp_dir" "$uv_tarball"
            fail "uv 解压失败"
        fi
        ensure_dir "$HOME/.local/bin"
        cp "$tmp_dir/uv-${arch}/uv" "$HOME/.local/bin/uv"
        chmod +x "$HOME/.local/bin/uv"
        if cp "$tmp_dir/uv-${arch}/uvx" "$HOME/.local/bin/uvx" 2>/dev/null; then
            chmod +x "$HOME/.local/bin/uvx"
        fi

        rm -rf "$tmp_dir" "$uv_tarball"
        success "uv ${uv_ver} 安装完成（SHA256 校验通过）。"
    fi

    export PATH="$HOME/.local/bin:$PATH"

    PYTHON_VERSION="${UV_PYTHON_VERSION:-3.14}"
    log "正在通过 uv 安装 Python ${PYTHON_VERSION}..."
    if uv python install "$PYTHON_VERSION"; then
        success "Python ${PYTHON_VERSION} 已通过 uv 安装。"
    elif uv python list 2>/dev/null | grep -qE "cpython-${PYTHON_VERSION}\."; then
        warn_track "uv python install ${PYTHON_VERSION} 失败，但检测到已有安装，继续。"
    else
        warn_track "Python ${PYTHON_VERSION} 安装失败 — 请手动运行 'uv python install ${PYTHON_VERSION}'。"
    fi

    success "uv 工具链就绪：$(uv --version 2>/dev/null)"
}
