# =============================================================================
# .zshenv — 环境变量（所有 zsh 实例都会加载）
# =============================================================================
# 警告：此处 PATH 添加保持最少。交互式 PATH 放在 .zshrc 中。
#       .zshenv 会被每一个 zsh 进程加载，包括脚本。
# =============================================================================

# --- 编辑器 -----------------------------------------------------------------
# 被 git、crontab 以及任何启动 $EDITOR 的程序使用。
export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-code}"

# --- 语言环境 ---------------------------------------------------------------
export LANG="en_US.UTF-8"
unset LC_ALL                         # 不设置全局覆盖；让 LC_* 子变量独立工作

# --- XDG 基础目录（freedesktop.org 规范）-----------------------------------
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# --- mise -------------------------------------------------------------------
export MISE_DATA_DIR="$HOME/.local/share/mise"

# --- OpenCode ---------------------------------------------------------------
export OPENCODE_CONFIG_DIR="$HOME/.config/opencode"

# --- uv（取消注释以设置公司/内部 PyPI 镜像）-------------------------------
# export UV_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"

# --- starship（配置路径，交互式和脚本都会用到）----------------------------
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# --- zsh ---------------------------------------------------------------------
# 将 zsh 补全缓存移至 cache 目录，避免污染 $HOME
export ZSH_COMPDUMP="$HOME/.cache/zsh/zcompdump-$HOST"

# --- less（bat 分页器相关配置）----------------------------------------------
export LESS="-R -F -X"
export LESSHISTFILE="-"
export BAT_THEME="Dracula"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
