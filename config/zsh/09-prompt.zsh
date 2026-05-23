# 密钥文件（可选 — 创建 ~/.env_secrets 并 chmod 600）
[ -f ~/.env_secrets ] && source ~/.env_secrets

# starship 提示符
eval "$(starship init zsh)"
