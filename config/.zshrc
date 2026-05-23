# =============================================================================
# .zshrc — ubuntu-bootstrap Shell 配置加载器
# =============================================================================
# 模块按编号顺序从 ~/.config/zsh/ 加载。
# 加载顺序：path → mise → completion → history → tools → aliases →
#           functions → fzf → prompt → plugins（syntax-highlighting 最后）。
# 要禁用某个模块，重命名它（例如 06-aliases.zsh → 06-aliases.zsh.disabled）。
# =============================================================================

# 如果有 ~/projects 目录则自动进入，否则停在 $HOME
if [ -d "$HOME/projects" ]; then
    cd "$HOME/projects" 2>/dev/null
fi

ZSH_MODULES="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

if [ -d "$ZSH_MODULES" ]; then
    for f in "$ZSH_MODULES"/*.zsh(N); do
        source "$f"
    done
fi
