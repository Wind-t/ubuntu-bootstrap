# zsh-autosuggestions
if [ -f ~/.local/share/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source ~/.local/share/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# zsh-syntax-highlighting（必须最后加载 — 官方文档要求）
if [ -f ~/.local/share/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source ~/.local/share/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# fastfetch（Shell 启动时显示系统信息，取消注释以启用）
# fastfetch

typeset -U path                                    # PATH 去重（必须在所有 PATH 修改之后）
path=( ${path:#*/games*} )                         # 移除游戏目录（开发机不需要）

# 清理 mise 内部变量（运行时不需要，可安全删除）
unset __MISE_DIFF __MISE_ORIG_PATH __MISE_SESSION 2>/dev/null
