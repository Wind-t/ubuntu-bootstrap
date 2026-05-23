# 导航
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# 安全操作（带确认提示）
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'

# 目录列表（优先 eza，否则 fallback ls）
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first --git'
    alias la='eza -la --icons --group-directories-first --git'
    alias lt='eza --tree --level=2 --icons'
    alias lta='eza --tree --icons -a'
else
    alias ls='ls --color=auto -h'
    alias ll='ls --color=auto -lh'
    alias la='ls --color=auto -lAh'
fi

# git
alias g='git'
alias ga='git add'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias lg='lazygit'

# 现代替代工具
command -v rg &>/dev/null && alias grep='rg'
command -v fd &>/dev/null && alias find='fd'
command -v bat &>/dev/null && alias cat='bat --paging=never'
command -v btop &>/dev/null && alias top='btop'

# uv
alias uvr='uv run'
alias uva='uv add'
alias uvs='uv sync'

# mise
alias mx='mise exec'
alias mi='mise install'
alias ml='mise list'

# Docker（如已安装）
if command -v docker &>/dev/null; then
    alias d='docker'
    alias dc='docker compose'
    alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
    alias ld='lazydocker'
fi

# 系统工具
alias ip='ip -color'
alias ports='ss -tlnp'
alias reload='exec zsh'
alias update='sudo apt update && sudo apt upgrade -y'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean'
alias du='dust'
alias df='df -h'
