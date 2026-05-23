# =============================================================================
# .profile — ubuntu-bootstrap 登录 Shell 回退（bash / sh 兼容）
# =============================================================================
# 此文件在 POSIX 登录 Shell 中执行。如果你使用 zsh，.zshrc 是主配置。
# .profile 保持最小化，作为安全网。
# =============================================================================

# --- PATH -------------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# --- mise（bash 用户）-------------------------------------------------------
if [ -x "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate bash)"
fi

# --- starship（bash 用户）---------------------------------------------------
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# --- 运行 zsh 时加载 .zshenv，但不加载 .zshrc（那是交互式的）---
if [ -n "${ZSH_VERSION:-}" ] && [ -f "$HOME/.zshenv" ]; then
    . "$HOME/.zshenv"
fi
