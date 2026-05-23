<p align="center">
  <b>ubuntu-bootstrap</b>
</p>

<p align="center">
  Ubuntu 开发环境一键部署 · 幂等 · CI 测试 · 版本锁定 · WSL 兼容
</p>

<p align="center">
  <a href="#快速开始">快速开始</a> ·
  <a href="#安装内容">安装内容</a> ·
  <a href="#使用方式">使用方式</a> ·
  <a href="#自定义">自定义</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/ubuntu-22.04%20%7C%2024.04%20%7C%2026.04%20%7C%20WSL-E95420?logo=ubuntu" alt="Ubuntu">
  <img src="https://img.shields.io/badge/version-1.2.0-blue" alt="Version">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="License"></a>
  <a href="https://github.com/Wind-t/ubuntu-bootstrap/actions"><img src="https://img.shields.io/github/actions/workflow/status/Wind-t/ubuntu-bootstrap/test.yml?branch=main" alt="CI"></a>
</p>

---

## 快速开始

```bash
git clone https://github.com/Wind-t/ubuntu-bootstrap.git
cd ubuntu-bootstrap
make
```

CI / Docker 环境（跳过交互）：

```bash
SKIP_INTERACTIVE=1 make
```

> 📖 完整教程、别名速查、第一天操作清单见 **[使用指南](docs/guide.md)**。

> [!WARNING]
> 不推荐 `curl | bash`。如需一行安装，请先阅读脚本内容：
> ```bash
> curl -fsSL https://raw.githubusercontent.com/Wind-t/ubuntu-bootstrap/main/bootstrap.sh -o bootstrap.sh
> less bootstrap.sh && bash bootstrap.sh
> ```

---

## 安装内容

<details open>
<summary><b>系统包</b> (apt)</summary>

`build-essential` `curl` `wget` `git` `unzip` `zip` `unar` `jq` `tree` `micro` `ca-certificates` `gnupg` `lsb-release` `software-properties-common` `locales` `xdg-utils` `zsh` `fzf`

</details>

<details open>
<summary><b>开发工具</b> (mise)</summary>

所有版本锁定在 [`config/mise.config.toml`](config/mise.config.toml)，Renovate 自动更新。

| 工具 | 用途 | 工具 | 用途 |
|------|------|------|------|
| node 24 | JavaScript LTS | ripgrep | 代码搜索 |
| fd | 文件查找 | bat | 语法高亮 cat |
| lazygit | Git TUI | delta | Git diff 渲染 |
| difftastic | 结构 diff | zoxide | 智能 cd |
| tealdeer | 精简 man | eza | 现代 ls |
| btop | 系统监控 | lazydocker | Docker TUI |
| dust | 磁盘分析 | yazi | 终端文件管理器 |
| zellij | 终端复用器 | fastfetch | 系统信息 |
| starship | Shell 提示符 | ruff | Python linter |
| gh | GitHub CLI | opencode | AI 编码助手 |

</details>

<details open>
<summary><b>Python 工具链</b> (uv) + <b>Zsh 插件</b></summary>

**uv**：Cargo 级速度的 pip 替代，安装 Python 3.14（可通过 `UV_PYTHON_VERSION` 指定版本）。

**Zsh 插件**：`zsh-autosuggestions`（历史建议）+ `zsh-syntax-highlighting`（语法高亮）。

</details>

---

## 使用方式

```bash
make              # 完整部署
bash bootstrap.sh --dry-run        # 预览（不执行）
bash bootstrap.sh --skip=dotfiles,zsh-plugins  # 跳过模块
```

| 命令 | 作用 |
|------|------|
| `make apt` / `make mise` / … | 单独安装某个模块 |
| `make help` | 查看所有目标 |
| `make verify` | 环境健康检查 |
| `bash verify.sh --strict` | 严格验证 |
| `make test` | shellcheck + 语法检查 + 干运行 + 严格验证 |
| `make clean` | 完全卸载 |

### Docker 验证

在纯净 Ubuntu 环境中验证完整部署流程：

```bash
# 默认 Ubuntu 24.04
docker build -t ubuntu-bootstrap-test .
docker run --rm ubuntu-bootstrap-test

# 指定 Ubuntu 版本
docker build --build-arg UBUNTU_VERSION=22.04 -t ubuntu-bootstrap-test .
docker run --rm ubuntu-bootstrap-test
```

---

## 环境变量

| 变量 | 作用 | 默认值 |
|------|------|--------|
| `SKIP_INTERACTIVE` | 设为 `1` 跳过 chsh、确认提示 | — |
| `UV_PYTHON_VERSION` | Python 版本 | `3.14` |
| `QUIET` | 设为 `1` 只显示警告和错误 | — |
| `NO_COLOR` | 设为 `1` 禁用 ANSI 颜色 | — |

---

## 自定义

Dotfile（`.zshrc`、`.gitconfig` 等）通过符号链接指向仓库 `config/` 目录。

```bash
micro ~/.zshrc      # 实际改的是 config/.zshrc
micro ~/.gitconfig  # 实际改的是 config/.gitconfig
```

添加个人配置——创建 `config/zsh/11-local.zsh`（不会被覆盖）：

```bash
export JAVA_HOME="/usr/lib/jvm/java-21"
alias mycmd='echo hello'
```

> [!NOTE]
> 首次运行会备份已有 dotfile（如 `~/.zshrc.bak.1716460000`），可手动合并。

---

## 架构

```
ubuntu-bootstrap/
├── bootstrap.sh              # 入口编排
├── Makefile                  # 统一入口
├── verify.sh                 # 环境健康检查
├── uninstall.sh              # 清理卸载
├── lib/
│   ├── common.sh             # 日志、错误处理、符号链接、manifest
│   └── setup-*.sh            # 6 个幂等模块（apt/locale/mise/uv/zsh-plugins/dotfiles）
├── config/
│   ├── mise.config.toml      # 声明式工具版本
│   └── .zshrc .gitconfig …   # dotfile 源文件
└── docs/
    └── guide.md              # 完整使用指南
```

每个 `setup_*` 模块可独立重跑，不会重复安装。失败时输出精确步骤定位和 warning 汇总。

---

## 贡献 & 许可

[完整指南](docs/guide.md) · [开发规范](AGENTS.md) · [变更记录](CHANGELOG.md)

MIT © 2026 [Wind-t](https://github.com/Wind-t)
