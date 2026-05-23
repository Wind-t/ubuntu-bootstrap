# 快速初始化 Python 项目（uv + mise venv 自动激活）
pyinit() {
    local project_name="${1:-.}"

    if [ "$project_name" != "." ]; then
        mkdir -p "$project_name" && cd "$project_name" || return 1
    fi

    if [ ! -f mise.toml ] || ! grep -q "_.python.venv" mise.toml 2>/dev/null; then
        if [ -f mise.toml ]; then
            printf '\n' >> mise.toml
        fi
        cat >> mise.toml <<'EOF'
[env]
_.python.venv = { path = ".venv", create = true }
EOF
        printf '\033[1;34m[INFO]\033[0m  已配置 mise.toml venv 自动激活。\n'
    fi

    echo "完成！进入/退出目录即可自动激活 venv。"
    echo "    然后：uv init && uv add <包名>"
}

# 创建目录并进入
mkcd() { mkdir -pv "$@" && cd "$@"; }

# 解压常见压缩包
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1"   ;;
            *.tar.gz)  tar xzf "$1"   ;;
            *.tar.xz)  tar xJf "$1"   ;;
            *.bz2)     bunzip2 "$1"   ;;
            *.gz)      gunzip "$1"    ;;
            *.tar)     tar xf "$1"    ;;
            *.tbz2)    tar xjf "$1"   ;;
            *.tgz)     tar xzf "$1"   ;;
            *.zip)     unzip "$1"     ;;
            *.7z)      7z x "$1"      ;;
            *.rar)     unrar x "$1"   ;;
            *)         echo "未知格式：$1" ;; 
        esac
    else
        echo "不是文件：$1"
    fi
}
