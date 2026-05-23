# mise（多语言版本管理器，缓存以加速启动）
_MISE_CACHE="$HOME/.cache/mise-activate.zsh"
_MISE_BIN="$HOME/.local/bin/mise"
_MISE_CFG="$HOME/.config/mise/config.toml"
if [[ ! -f "$_MISE_CACHE" ]] || \
   [[ -n "$(find "$_MISE_BIN" "$_MISE_CFG" -newer "$_MISE_CACHE" 2>/dev/null | head -1)" ]]; then
    mkdir -p "$(dirname "$_MISE_CACHE")"
    "$_MISE_BIN" activate zsh > "$_MISE_CACHE" 2>/dev/null
fi
source "$_MISE_CACHE"
