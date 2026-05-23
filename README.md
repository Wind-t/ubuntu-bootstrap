# ubuntu-bootstrap — Ubuntu 开发环境一键部署

一条命令，环境就绪。幂等，安全重复运行。支持 Ubuntu 22.04 / 24.04 / 26.04 原生环境。

## 快速开始

```bash
git clone https://github.com/Wind-t/ubuntu-bootstrap.git
cd ubuntu-bootstrap
make
```

> ⚠️ 不推荐 `curl | bash` 方式（中间人攻击风险）。如需一行安装，请先阅读 `bootstrap.sh` 内容后再执行：

```bash
curl -fsSL https://raw.githubusercontent.com/Wind-t/ubuntu-bootstrap/main/bootstrap.sh -o bootstrap.sh
less bootstrap.sh
bash bootstrap.sh
```

CI/Docker 无交互运行：

```bash
SKIP_INTERACTIVE=1 make
```

## 安装内容

### 系统包（apt）

build-essential, curl, wget, git, unzip, zip, unar, jq, tree, micro, ca-certificates, gnupg, lsb-release, software-properties-common, locales, xdg-utils, zsh, fzf

### 开发工具（mise 管理）

mise 是一个 polyglot 版本管理器，从 GitHub Releases 自动下载二进制文件。所有工具声明在 `config/mise.config.toml`：

| 工具 | 用途 |
|------|------|
| node 24 | JavaScript 运行时 (LTS) |
| go 1.26 | Go 语言工具链 |
| ripgrep (rg) | 超速代码搜索 |
| fd | 更友好的 find |
| bat | 带语法高亮的 cat |
| lazygit | Git TUI |
| delta | Git diff 渲染 |
| difftastic | 结构 diff |
| zoxide | 智能 cd |
| tealdeer (tldr) | 精简版 man |
| eza | 现代 ls |
| btop | 系统监控 |
| lazydocker | Docker TUI |
| dust (du) | 磁盘分析 |
| yazi | 终端文件管理器 |
| zellij | 终端复用器 |
| fastfetch | 系统信息 |
| starship | 跨 Shell 提示符 |
| ruff | Python linter |
| gh | GitHub CLI |
| opencode | AI 编码助手 |

### Python 工具链（uv 管理）

- uv（Cargo 级速度的 pip 替代）
- Python 3.14（可通过 `UV_PYTHON_VERSION` 指定版本）

### Zsh 插件

- zsh-autosuggestions（历史建议）
- zsh-syntax-highlighting（语法高亮）

## 环境变量

| 变量 | 作用 |
|------|------|
| `SKIP_INTERACTIVE=1` | 跳过交互式操作（chsh），CI/Docker 用 |
| `UV_PYTHON_VERSION` | 指定 Python 版本（默认 3.14） |
| `QUIET=1` | 只显示警告和错误 |
| `NO_COLOR=1` | 禁用颜色输出（管道/日志友好） |

## 使用方式

```bash
# 完整部署
make

# 或直接运行脚本（等价）
bash bootstrap.sh

# 预览（不执行）
bash bootstrap.sh --dry-run

# 跳过指定模块
bash bootstrap.sh --skip=dotfiles,zsh-plugins

# 单独安装某个模块
make apt          # 只装系统包
make mise         # 只装开发工具

# 查看所有可用目标
make help

# 验证环境
make verify
bash verify.sh --verbose     # 详细输出
bash verify.sh --fix         # 验证 + 自动修复
bash verify.sh --strict      # 严格模式

# 代码检查 + 验证
make test

# 卸载
bash uninstall.sh
bash uninstall.sh --all      # 完全清理
make clean
```

### Docker 验证

在纯净 Ubuntu 24.04 环境中验证完整部署流程：

```bash
docker build -t ubuntu-bootstrap-test .
docker run --rm ubuntu-bootstrap-test
```

## 自定义配置

所有 dotfile（`.zshrc`、`.gitconfig` 等）都是**符号链接**，指向仓库中的 `config/` 目录。修改方法：

### 日常编辑

直接编辑 `~/.zshrc`、`~/.gitconfig` 即可，修改会自动落到 `config/` 源文件里。重装系统后 clone 仓库回来，你的修改还在。

```
micro ~/.zshrc      # 实际改的是 config/.zshrc
micro ~/.gitconfig  # 实际改的是 config/.gitconfig
```

### 添加个人环境变量 / alias / 函数

不要直接改 `config/.zshrc`，新建一个本地模块文件。zsh 会按编号顺序加载 `config/zsh/` 下的所有 `.zsh` 文件：

```bash
# 新建 config/zsh/11-local.zsh
export JAVA_HOME="/usr/lib/jvm/java-21"
export MY_API_KEY="xxx"

alias mycmd='echo hello'
```

这个文件不会被 `bootstrap.sh` 覆盖，也不会被 git 追踪（加入 `.gitignore` 即可）。

### 迁移旧配置

`bootstrap.sh` 首次运行时会备份已有的 dotfile（例如 `~/.zshrc.bak.1716460000`）。如果旧配置里有需要保留的内容，手动合并到 `config/` 对应的源文件中：

```bash
# 查看备份
cat ~/.zshrc.bak.*
cat ~/.gitconfig.bak.*

# 合并到源文件（通过 symlink 直接编辑或改 config/ 目录）
micro ~/.zshrc
```

### 注意

- **不要** `rm ~/.zshrc` 然后创建一个普通文件替代，这会破坏符号链接。下次运行 `bootstrap.sh` 会备份它并重新建 symlink。
- 想要某个 zsh 模块不加载，在 `config/zsh/` 下把对应文件重命名即可（如 `06-aliases.zsh.disabled`）。

## 架构

```
ubuntu-bootstrap/
├── bootstrap.sh          # 入口：轻量编排器
├── Makefile              # 统一入口（make / make test / make clean）
├── verify.sh             # 环境健康检查
├── uninstall.sh          # 清理卸载
├── Dockerfile            # 纯净环境验证镜像
├── VERSION               # 语义化版本号
├── .github/
│   └── workflows/
│       └── lint.yml      # CI：shellcheck 自动检查
├── lib/
│   ├── common.sh         # 日志、错误处理、文件操作
│   ├── setup-apt.sh      # 系统包
│   ├── setup-locale.sh   # locale + 默认 shell
│   ├── setup-mise.sh     # mise + 开发工具
│   ├── setup-uv.sh       # uv + Python
│   ├── setup-zsh-plugins.sh  # zsh 插件
│   └── setup-dotfiles.sh     # dotfile 符号链接
└── config/
    ├── mise.config.toml  # 声明式工具版本管理
    ├── starship.toml     # 提示符配置
    ├── .zshrc, .zshenv, .profile, .gitconfig, .gitignore_global
    └── zsh/              # zsh 模块化配置
```

每个 `lib/setup-*.sh` 封装一个独立的配置步骤，由 `bootstrap.sh` 按序调用。幂等设计：每个模块可独立重新运行，不会重复安装。失败时有明确的步骤定位和 warning 汇总。
