# zoxide（智能 cd，在 compinit 之后添加补全）
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# 快捷键绑定
bindkey -e                                          # Emacs 模式
bindkey '^ ' autosuggest-accept                     # Ctrl+Space：接受建议
bindkey '^[[Z' reverse-menu-complete                # Shift+Tab：反向补全
