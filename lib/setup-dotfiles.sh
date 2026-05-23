#!/usr/bin/env bash
# =============================================================================
# lib/setup-dotfiles.sh — dotfile 符号链接 (ubuntu-bootstrap)
# =============================================================================
set -euo pipefail

# SCRIPT_DIR is set by bootstrap.sh before sourcing this module.
# Guard: fallback for standalone sourcing (e.g. debugging).
: "${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

setup_dotfiles() {
    set_step "dotfiles"
    section "Dotfiles"

    backup_then_link "$SCRIPT_DIR/config/.zshrc"       "$HOME/.zshrc"
    backup_then_link "$SCRIPT_DIR/config/.zshenv"      "$HOME/.zshenv"
    backup_then_link "$SCRIPT_DIR/config/.profile"     "$HOME/.profile"
    backup_then_link "$SCRIPT_DIR/config/.gitconfig"   "$HOME/.gitconfig"
    backup_then_link "$SCRIPT_DIR/config/.gitignore_global" "$HOME/.gitignore_global"

    ensure_dir "$HOME/.config"
    backup_then_link "$SCRIPT_DIR/config/starship.toml" "$HOME/.config/starship.toml"

    local ZSH_MODULE_SRC="$SCRIPT_DIR/config/zsh"
    local ZSH_MODULE_DST="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
    ensure_dir "$ZSH_MODULE_DST"
    for f in "$ZSH_MODULE_SRC"/*.zsh; do
        [ -f "$f" ] || continue
        backup_then_link "$f" "$ZSH_MODULE_DST/$(basename "$f")"
    done

    success "Dotfiles 链接完成。"
}
