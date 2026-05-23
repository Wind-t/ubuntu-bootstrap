# fzf（模糊查找器）
if command -v fzf &>/dev/null; then
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    if fzf --zsh &>/dev/null 2>&1; then
        eval "$(fzf --zsh)"
    fi
fi
