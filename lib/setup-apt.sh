#!/usr/bin/env bash
# =============================================================================
# lib/setup-apt.sh — 系统软件包 (ubuntu-bootstrap)
# =============================================================================
set -euo pipefail

setup_apt() {
    set_step "system packages"
    section "系统软件包 (apt)"

    local packages=(
        build-essential
        curl
        wget
        git
        unzip
        zip
        unar
        jq
        tree
        ca-certificates
        gnupg
        lsb-release
        software-properties-common
        locales
        xdg-utils
        zsh
        fzf
    )

    # 检测并发 apt 锁
    if fuser /var/lib/dpkg/lock-frontend &>/dev/null; then
        fail "检测到另一个 apt 进程正在运行。请等待它完成后再试。"
    fi

    # 只安装缺失的包
    local missing=()
    local pkg
    for pkg in "${packages[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        log "所有 ${#packages[@]} 个系统包已安装 — 跳过。"
        return 0
    fi

    log "正在更新软件包列表..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq

    log "正在安装 ${#missing[@]} 个缺失的系统包..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq -o Acquire::Retries=3 "${missing[@]}" || {
        log "部分包下载失败，尝试修复..."
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --fix-missing -o Acquire::Retries=3 "${missing[@]}" || \
            fail "系统包安装失败（网络问题？）"
    }

    success "系统软件包安装完成。"
}
