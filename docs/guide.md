# ubuntu-bootstrap 完全指南

## 这是什么

一句话：**在新机器或纯净 Ubuntu 上跑一条命令，开发环境全部就绪。**

你拿到一台刚装完系统的 Ubuntu（22.04 / 24.04 / 26.04），或者 Windows 上的 WSL Ubuntu，克隆这个仓库，`make` 一下，系统包、开发工具链、Shell 配置、dotfiles 全部到位。跑完就能写代码。

核心设计原则：

- **幂等** — 跑十次和跑一次效果一样，不会重复安装或覆盖已有配置
- **版本锁定** — 每个工具钉死具体版本，你和同事的 ripgrep 版本永远一致
- **可逆** — 一键卸载，恢复原状
- **CI 验证** — 三个 Ubuntu 版本 + 幂等性 + 卸载重装，自动化测试通过才叫「能用」

---

## 安装了什么：逐项拆解

### 一、系统基础包（apt）

```
build-essential    — C/C++ 编译工具链 (gcc, g++, make)
curl wget          — HTTP 下载工具
git                — 版本控制
unzip zip unar     — 压缩/解压
jq                 — 命令行 JSON 处理器
tree               — 目录树可视化
- **nano** — 默认终端编辑器（Ubuntu 自带）
ca-certificates    — SSL 证书
gnupg              — GPG 加密
lsb-release        — 发行版信息
software-properties-common — add-apt-repository
locales            — 语言环境
xdg-utils          — Linux 桌面集成 (xdg-open 等)
zsh                — Shell（替代 bash）
fzf                — 模糊搜索（Ctrl+R 历史搜索、Ctrl+T 文件搜索）
```

这些都是 Ubuntu 开发环境的基本盘。没这些你连 `git clone` 都跑不了。

---

### 二、开发工具（mise 管理）

mise 是一个「多语言版本管理器」——它负责下载、安装、管理下面这 20 个工具的精确版本。

| 工具            | 分类   | 你用它干什么                                                                       |
|-----------------|--------|------------------------------------------------------------------------------------|
| `node 24`       | 运行时 | JavaScript/TypeScript 项目。LTS 版本，npm 自带                                     |
| `ripgrep (rg)`  | 搜索   | 替代 grep。递归搜代码目录，毫秒级出结果。`rg "function" src/`                        |
| `fd`            | 搜索   | 替代 find。语法更友好：`fd "*.ts"` 而不是 `find . -name "*.ts"`                     |
| `bat`           | 查看   | 替代 cat。语法高亮 + 行号 + Git diff 标记。`bat main.rs`                            |
| `lazygit`       | Git    | 终端里的 Git GUI。暂存/提交/分支切换/rebase，全键盘操作                             |
| `delta`         | Git    | 增强 git diff 输出。双栏对比、行号、语法高亮                                        |
| `difftastic`    | Git    | 结构级 diff。不是按行比，是按语法树比——变量改名不会被当成整行改动                    |
| `zoxide`        | 导航   | 替代 cd。你 cd 过的目录它记住，`z project` 就跳过去                                  |
| `tealdeer (tldr)`| 帮助  | 替代 man。只显示常用例子，不给你甩 500 行手册                                       |
| `eza`           | 文件   | 替代 ls。颜色区分文件类型、Git 状态标记、树形展示                                   |
| `btop`          | 监控   | 终端里的资源监控。CPU/内存/磁盘/网络，比 htop 好看                                  |
| `lazydocker`    | Docker | 终端里的 Docker GUI。查看容器/镜像/日志，一键进容器                                  |
| `dust`          | 磁盘   | 替代 du。直观展示哪个目录占空间最大                                                 |
| `yazi`          | 文件管理 | 终端文件管理器。图片预览、多面板、vim 键位                                         |
| `zellij`        | 终端   | 终端复用器。分屏、标签页、持久会话（类似 tmux，但更易上手）                         |
| `fastfetch`     | 信息   | 替代 neofetch。显示系统信息，纯性能没花哨                                           |
| `starship`      | 美化   | Shell 提示符。显示 Git 分支、语言版本、命令耗时                                      |
| `ruff`          | Lint   | Python 代码检查。比 flake8 快 100 倍                                                |
| `gh`            | GitHub | GitHub CLI。`gh pr create`、`gh issue list`，不用开浏览器                            |
| `opencode`      | AI     | AI 编码助手                                                                        |

---

### 三、Python 工具链（uv 管理）

- **uv** — 替代 pip。Rust 写的，比 pip 快 10-100 倍。同时管理虚拟环境和 Python 版本
- **Python 3.14** — 通过 uv 安装，不是系统 apt 版本（避免搞乱 Ubuntu 自带的 Python）

```bash
# 装完后直接用
uv venv                    # 创建虚拟环境
uv pip install requests    # 装包，秒级完成
uv python install 3.13    # 换个版本也行
```

---

### 四、Zsh 插件

| 插件                       | 效果                                                               |
|----------------------------|--------------------------------------------------------------------|
| `zsh-autosuggestions`      | 你打命令时，灰色字提示你历史中匹配的命令。按 → 键补全                |
| `zsh-syntax-highlighting`  | 命令敲对了变绿，敲错了变红。输入时实时反馈                           |

---

### 五、Dotfiles（符号链接）

`config/` 目录下的所有配置文件通过**符号链接**挂到 `$HOME` 目录：

```
config/.zshrc              →  ~/.zshrc                      # zsh 启动配置
config/.zshenv             →  ~/.zshenv                     # 环境变量
config/.profile            →  ~/.profile                    # 登录 shell 配置
config/.gitconfig          →  ~/.gitconfig                  # Git 全局配置
config/.gitignore_global   →  ~/.gitignore_global           # 全局 gitignore
config/starship.toml       →  ~/.config/starship.toml       # 提示符样式
config/zsh/*.zsh           →  ~/.config/zsh/*.zsh           # zsh 模块（按编号加载）
```

**关键设计**：你编辑 `~/.zshrc`，实际上改的是仓库里的 `config/.zshrc`。你不需要记忆「哪个文件在哪个位置」——改就完了。换机器时 git pull 一下，所有配置同步。

---

### 六、快捷键与别名

配置加载后会获得一套开箱即用的操作习惯。全部定义在 `config/zsh/06-aliases.zsh` 和 `config/zsh/07-functions.zsh`。

#### 导航

| 输入 | 等价于 | 效果 |
|------|--------|------|
| `..` | `cd ..` | 上层目录 |
| `...` | `cd ../..` | 上两层 |
| `....` | `cd ../../..` | 上三层 |
| `~` | `cd ~` | 回 HOME |
| `mkcd dir` | `mkdir -p dir && cd dir` | 创建并进入（函数） |

#### 安全操作

| 输入 | 实际执行 | 安全机制 |
|------|---------|---------|
| `cp` | `cp -iv` | 覆盖前确认 + 显示进度 |
| `mv` | `mv -iv` | 同上 |
| `rm` | `rm -iv` | 删除前逐条确认 |
| `mkdir` | `mkdir -pv` | 自动创建父目录 + 显示进度 |

#### 文件列表

| 别名 | 实际命令 | 效果 |
|------|---------|------|
| `ls` | `eza --icons --group-directories-first` | 彩色图标列表，目录优先 |
| `ll` | `eza -l --icons --git` | 详细列表 + Git 状态标记 |
| `la` | `eza -la --icons --git` | 详细列表 + 隐藏文件 |
| `lt` | `eza --tree --level=2 --icons` | 树形展示（2 层） |
| `lta` | `eza --tree --icons -a` | 树形展示 + 隐藏文件 |

> 若 eza 未安装，自动回退到传统的 `ls --color=auto`。

#### Git（全部两字母）

| 别名 | 等价命令 |
|------|---------|
| `g` | `git` |
| `ga` | `git add` |
| `gs` | `git status` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gl` | `git pull` |
| `gd` | `git diff` |
| `gco` | `git checkout` |
| `gb` | `git branch` |
| `lg` | `lazygit` — 终端 Git GUI |

#### 现代工具替代

| 你输入 | 实际运行 | 为什么更好 |
|--------|---------|-----------|
| `grep` | `rg` (ripgrep) | 默认递归、忽略 `.gitignore`、彩色输出 |
| `find` | `fd` | 语法更短，自动跳过 `.git` |
| `cat` | `bat --paging=never` | 语法高亮 + 行号 + Git 变更标记 |
| `top` | `btop` | 图形化 CPU/内存/磁盘/网络面板 |
| `du` | `dust` | 直观展示每个目录占用空间 |
| `df` | `df -h` | 人类可读的磁盘用量 |

#### uv（Python）

| 别名 | 等价命令 |
|------|---------|
| `uvr` | `uv run` |
| `uva` | `uv add` |
| `uvs` | `uv sync` |

#### mise

| 别名 | 等价命令 |
|------|---------|
| `mx` | `mise exec` — 以指定工具版本执行命令 |
| `mi` | `mise install` — 安装/更新工具 |
| `ml` | `mise list` — 查看已安装工具 |

#### Docker（如果 Docker 已安装）

| 别名 | 等价命令 |
|------|---------|
| `d` | `docker` |
| `dc` | `docker compose` |
| `dps` | `docker ps --format table` — 格式化容器列表 |
| `ld` | `lazydocker` — 终端 Docker GUI |

#### 系统工具

| 输入 | 实际执行 | 效果 |
|------|---------|------|
| `ip` | `ip -color` | 彩色网络信息 |
| `ports` | `ss -tlnp` | 查看所有监听端口 |
| `reload` | `exec zsh` | 重载 zsh 配置（改过 `.zshrc` 后执行） |
| `update` | `sudo apt update && sudo apt upgrade -y` | 一键更新系统 |
| `cleanup` | `sudo apt autoremove -y && sudo apt autoclean` | 清理系统垃圾 |

#### 快捷键

| 按键 | 效果 |
|------|------|
| `Ctrl+R` | fzf 历史命令搜索（模糊匹配） |
| `Ctrl+T` | fzf 文件搜索并插入路径 |
| `Ctrl+Space` | 接受 zsh-autosuggestions 建议 |
| `Shift+Tab` | 反向遍历补全列表 |

> fzf 配置：`FZF_DEFAULT_COMMAND` 默认使用 `fd`（自动跳过 `.git`）。弹窗高度 40%，底部对齐，带边框。

#### 快捷函数

| 函数 | 用法 | 效果 |
|------|------|------|
| `pyinit` | `pyinit my-project` | 创建 Python 项目目录 + 配置 mise venv 自动激活 |
| `mkcd` | `mkcd some/dir` | 创建目录并立即进入 |
| `extract` | `extract archive.tar.gz` | 解压任意格式压缩包（tar.gz / zip / 7z / rar / bz2 / xz） |

---

### 七、Git 增强配置

装完后你的 Git 体验会被大幅升级，全部定义在 `config/.gitconfig`。

#### Git 别名

| 别名 | 等价命令 | 效果 |
|------|---------|------|
| `git lg` | `git log --graph --pretty=format:…` | 彩色图形式提交历史，一眼看清分支结构 |
| `git lga` | 同上 `--all` | 所有分支的提交图 |
| `git st` | `git status -sb` | 精简状态（分支名 + 改动文件列表） |
| `git amend` | `git commit --amend --no-edit` | 追加到上一次提交，不改 commit message |
| `git undo` | `git reset --soft HEAD~1` | 撤销上一次提交，改动回到暂存区 |
| `git diffc` | `git diff --cached` | 只看已暂存（staged）的改动 |
| `git aliases` | `git config --get-regexp alias` | 列出所有 Git 别名 |
| `git br` | `git branch` | 分支列表 |
| `git co` | `git checkout` | 切换分支 |

#### Git 自动化

| 配置 | 效果 |
|------|------|
| `autoSetupRemote = true` | 新分支首次 `git push` 时自动在远端创建，无需 `--set-upstream` |
| `fetch.prune = true` | 每次 fetch 自动清理已删除的远端分支 |
| `defaultBranch = main` | `git init` 默认分支为 main |
| `editor = $EDITOR` | `git commit`（不加 -m）时打开 `$EDITOR` 编辑器 |
| `url.insteadOf` | `git://` 自动替换为 `https://` |

#### Diff 视觉增强

| 配置 | 效果 |
|------|------|
| `pager = delta` | 默认 diff 输出使用 delta（双栏对比 + 行号 + 语法高亮） |
| `difftool = difftastic` | `git difftool` 使用 difftastic（结构级 diff，按语法树对比） |
| `conflictstyle = diff3` | 合并冲突时显示三方对比（你的版本 + 公共祖先 + 对方的版本），更容易判断该删哪段 |
| `colorMoved = default` | 移动的代码块用不同颜色标记 |

#### 实际效果对比

```bash
# 没配置前
git log          # 满屏白字，分不清哪个 commit 属于哪个分支

# 配置后
git lg           # 彩色图形，一眼看出主线/分支/合并点
git st           # 两行精简状态
git diff         # delta 渲染，行号+语法高亮+改动标记
git difftool     # difftastic 结构对比，变量改名不被当成整行改动
```

---

### 八、Shell 增强

#### 命令历史

| 配置 | 数值 | 效果 |
|------|------|------|
| `HISTSIZE` | 50000 | 内存中保存 5 万条历史 |
| `SAVEHIST` | 50000 | 磁盘上保存 5 万条历史 |
| 去重 | 三重去重 | 连续相同命令只保留一条；搜索时跳过重复；保存时不写重复 |
| 跨会话共享 | ✅ | 开一个新终端，之前的命令历史全部可用 |

> 配合 `Ctrl+R`（fzf 模糊搜索），你半年前敲过的一条命令几秒钟就能找回来。

#### 命令补全

| 特性 | 效果 |
|------|------|
| 菜单选择 | 按 Tab 弹出补全菜单，方向键选择 |
| 大小写不敏感 | `git ch` <Tab> → 匹配 `Git Checkout`、`GIT CHERRY-PICK` 等 |
| mise 工具补全 | `mise` <Tab> → 列出所有子命令；工具名自动补全 |

#### 提示符（Starship）

装完后你的终端提示符从单调的 `$` 变成这样：

```
   sugar  ~/projects/ubuntu-bootstrap   main ✓1   v24.5.0  20:30 
  $
```

每一段的含义：

| 显示内容 | 来源 | 何时出现 |
|---------|------|---------|
| 🐧 Ubuntu 图标 | 系统检测 | 始终 |
| `sugar` | 当前用户名 | 始终 |
| `~/projects/...` | 当前目录 | 始终（超过 3 层会缩写成 `…/`） |
| ` main` | Git 分支名 | 在 Git 仓库中 |
| `✓1` | Git 状态（1 个已暂存文件） | 有未提交改动时 |
| ` v24.5.0` | Node.js 版本 | 目录下有 `package.json` 时 |
| `🐍 v3.14.0` | Python 版本 | 目录下有 `*.py` 或虚拟环境时 |
| `🦀 v1.85.0` | Rust 版本 | 目录下有 `Cargo.toml` 时 |
| `20:30` | 当前时间 | 始终 |
| `$` | 输入光标 | 始终 |

> 你 cd 到一个项目目录，提示符自动告诉你用的是哪个语言版本，不需要敲 `node --version`。

---

### 九、环境变量一览

安装后自动设置的关键环境变量（`config/.zshenv`）：

| 变量 | 值 | 作用 |
|------|-----|------|
| `EDITOR` | `nano` | Git commit、crontab 等默认编辑器 |
| `VISUAL` | `code` | GUI 编辑器指向 VS Code |
| `LANG` | `en_US.UTF-8` | 系统语言环境 |
| `XDG_CONFIG_HOME` | `~/.config` | 配置文件目录（符合 freedesktop 规范） |
| `XDG_DATA_HOME` | `~/.local/share` | 数据文件目录 |
| `XDG_CACHE_HOME` | `~/.cache` | 缓存目录 |
| `MISE_DATA_DIR` | `~/.local/share/mise` | mise 安装的工具放这里 |
| `STARSHIP_CONFIG` | `~/.config/starship.toml` | 提示符样式配置 |
| `BAT_THEME` | `Dracula` | bat 语法高亮主题 |
| `MANPAGER` | `bat -l man -p` | man 手册页用 bat 渲染（语法高亮） |
| `LESS` | `-R -F -X` | less 分页器：彩色输出 + 内容少于一屏直接退出 |
| `OPENCODE_CONFIG_DIR` | `~/.config/opencode` | OpenCode AI 助手配置 |

> 可选：在 `~/.env_secrets` 中存放敏感环境变量（如 API Key），该文件已被 `.zshenv` 自动加载且受 `.gitignore` 保护。

---

### 十、装完第一天：操作清单

按这个顺序体验一遍，你就能感受到每个工具的价值。

**第一步：重启终端**

```bash
exec zsh
```

看到全新的 Starship 提示符，你的终端已经脱胎换骨。

**第 1 分钟：导航**

```bash
cd ~/projects    # 自动进入（.zshrc 配置的默认目录）
..               # 回上一层
...              # 回上两层
z ubuntu         # zoxide 智能跳转——你 cd 过一次 ubuntu-bootstrap 后就能直接跳
```

**第 3 分钟：看文件**

```bash
ls               # 彩色图标列表
ll               # 详细列表 + 每个文件的 Git 状态
lt               # 树形图
cat README.md    # 语法高亮 + 行号（实际上是 bat）
```

**第 5 分钟：搜东西**

```bash
rg "setup_" lib/        # 搜代码（ripgrep），毫秒级
fd "*.zsh"              # 找文件（fd）
Ctrl+T                  # fzf 文件搜索，选一个文件插入路径
Ctrl+R setup            # fzf 历史搜索，找到之前敲过的 setup 命令
```

**第 7 分钟：看看系统**

```bash
top              # btop 图形化监控，CPU/内存/磁盘/网络一目了然
du               # dust 磁盘分析，一眼看到底哪个目录占空间
ports            # 查看所有监听端口
fastfetch        # 系统信息概览
```

**第 10 分钟：Git 工作流**

```bash
cd ubuntu-bootstrap
gs               # git status -sb，看看改了哪些文件
gd               # git diff，delta 渲染的彩色双栏对比
git difftool     # difftastic 结构 diff，按 AST 对比
gc -m "message"  # git commit
gp               # git push（新分支自动创建远端）
git lg           # 彩色图形式提交历史
```

**第 15 分钟：写 Python**

```bash
pyinit hello-world     # 一键创建 Python 项目（自动配置 venv）
cd hello-world         # 进入目录，Starship 提示符立即显示 🐍 v3.14
uv init                # 初始化 pyproject.toml
uva add requests       # uv add（比 pip install 快 10 倍）
uvr python -c "import requests; print('hello')"  # uv run
```

**第 20 分钟：分屏工作**

```bash
zellij           # 启动终端复用器
# Ctrl+O → D    分右屏
# Ctrl+O → 方向键 在面板间跳转
# Ctrl+O → Z    当前面板全屏
# Ctrl+O → X    关闭当前面板
```

**全天候使用的肌肉记忆**

| 操作 | 按键 |
|------|------|
| 搜历史命令 | `Ctrl+R` |
| 搜文件并插入路径 | `Ctrl+T` |
| 补全命令 | `Tab`（菜单选择） |
| 反向遍历补全 | `Shift+Tab` |
| 接受建议 | `Ctrl+Space` |
| 重载 zsh | `reload`（改了配置后执行） |
| 系统更新 | `update` |
| 清理垃圾 | `cleanup` |

---

## 怎么用

### 安装

```bash
git clone https://github.com/Wind-t/ubuntu-bootstrap.git
cd ubuntu-bootstrap
make
```

> **WSL 用户注意**：请将仓库克隆到 Linux 分区（`~/ubuntu-bootstrap`），不要放在 `/mnt/c/` 下（Windows 分区不支持 Linux 符号链接）。脚本会自动检测 WSL 环境并跳过不适用的操作。

### 不同场景

```bash
# CI / Docker（不弹出交互提示）
SKIP_INTERACTIVE=1 make

# 静默模式（只看警告和错误）
QUIET=1 make

# 预览——只显示要做什么，不真做
bash bootstrap.sh --dry-run

# 跳过某些模块
bash bootstrap.sh --skip=dotfiles,zsh-plugins
bash bootstrap.sh --skip=uv          # 不装 Python
bash bootstrap.sh --skip=mise        # 不装开发工具

# 单独装一个模块
make apt        # 只装系统包
make mise       # 只装开发工具
make uv         # 只装 Python
make dotfiles   # 只链接配置文件
```

### 验证

```bash
make verify                  # 标准健康检查
bash verify.sh --verbose     # 详细输出，能看每步的命令
bash verify.sh --strict      # 严格模式，可选检查也视为失败
bash verify.sh --fix         # 自动修复常见问题（比如文件权限不对）
```

验证会检查 8 大类：

1. 系统是不是 Ubuntu
2. zsh 是不是默认 Shell
3. mise 管理的 19 个工具是否全部可用
4. Python 和 uv 是否正常
5. apt 安装的工具（fzf、tree）
6. dotfile 符号链接是否正确
7. zsh 插件是否存在
8. 环境变量和权限

### 测试

```bash
make test        # shellcheck + 语法检查 + 干运行 + 严格验证
make test-docker # Docker 里跑完整流程：安装 → 验证 → 幂等 → 卸载 → 重装
```

### 卸载

```bash
bash uninstall.sh              # 交互模式（删之前问你）
bash uninstall.sh --all        # 同时删 ~/.local/bin 里的二进制
bash uninstall.sh --all --yes  # 完全清理，不询问
make clean                     # 等价于上面这个
```

卸载会做什么：

1. 按运行时记录（manifest）解除所有符号链接
2. 如果 manifest 丢了，回退到编译时定义的列表
3. 清理 zsh 插件目录
4. 清理 mise 和 zsh 缓存
5. `--all` 时清空 `~/.local/bin`

---

## 自定义

### 添加自己的 dotfile

1. 在 `config/` 下放你的文件，比如 `config/.tmux.conf`
2. 在 `lib/setup-dotfiles.sh` 里加一行：

   ```bash
   backup_then_link "$SCRIPT_DIR/config/.tmux.conf" "$HOME/.tmux.conf"
   ```

3. 在 `lib/common.sh` 的 `UB_DOTFILE_DESTS` 数组里加 `"$HOME/.tmux.conf"`

### 添加个人 zsh 配置

在 `config/zsh/` 下创建 `11-local.zsh`（不会被覆盖）：

```bash
# config/zsh/11-local.zsh
export JAVA_HOME="/usr/lib/jvm/java-21"
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```

编号 11 确保它在所有内置模块之后加载。

### 换个 Python 版本

```bash
UV_PYTHON_VERSION=3.13 make
```

默认是 3.14。

---

## 架构一览

```
ubuntu-bootstrap/
├── bootstrap.sh                    # 入口脚本。解析参数、编排队列
├── Makefile                        # 常用命令快捷入口（make / make test / make clean）
├── verify.sh                       # 环境健康检查（8 大类，支持 verbose/strict/fix）
├── uninstall.sh                    # 卸载脚本（按 manifest 或 dotfile list 清理）
├── lib/
│   ├── common.sh                   # 基础设施：日志系统、符号链接、下载校验、manifest
│   ├── setup-apt.sh                # apt 系统包（幂等：只装缺失的）
│   ├── setup-locale.sh             # locale 生成 + 默认 Shell 设置
│   ├── setup-mise.sh               # mise 安装 + 20 个开发工具
│   ├── setup-uv.sh                 # uv 安装 + Python
│   ├── setup-zsh-plugins.sh        # zsh 插件（clone/update）
│   └── setup-dotfiles.sh           # 符号链接 dotfiles + 写 manifest
├── config/
│   ├── mise.config.toml            # 声明式工具列表（Renovate 自动更新版本）
│   ├── .zshrc / .gitconfig / ...   # dotfile 源文件
│   └── zsh/                        # zsh 模块（按编号顺序加载）
├── Dockerfile                      # CI 集成测试（支持 22.04/24.04/26.04）
├── .github/
│   ├── workflows/
│   │   ├── lint.yml                # shellcheck + 语法检查（快速反馈）
│   │   └── test.yml                # 集成测试矩阵 + 幂等性 + skip 组合
│   └── renovate.json               # 自动检测 mise 工具新版本
├── docs/
│   └── guide.md                    # 本文档
├── CHANGELOG.md                    # 版本变更记录
└── AGENTS.md                       # 开发规范（给 AI 和维护者看）
```

---

## 常见问题

**Q: 我装了之后 zsh 还是 bash？**

A: 重启终端或运行 `exec zsh`。如果还是不行，手动 `chsh -s $(which zsh)`。

**Q: 跑到一半网络断了？**

A: 直接重跑 `make`。脚本是幂等的——已安装的会跳过，只补装漏掉的。

**Q: 我不想装 zellij / yazi / btop？**

A: 编辑 `config/mise.config.toml`，删掉对应行，然后跑 `mise install`。或者 fork 仓库自己维护一份。

**Q: 能用在非 Ubuntu 系统上吗？**

A: 不保证。Debian 可能行，其他发行版大概率不行（apt 包名、locale 机制都不同）。

**Q: 和 `curl | bash` 一键脚本有什么区别？**

A: 那个你连里面是什么都不知道。这个你先看 `bootstrap.sh`（124 行，有注释），看了再决定跑不跑。
