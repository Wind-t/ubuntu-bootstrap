# Changelog

本文档记录 ubuntu-bootstrap 的所有显著变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [Unreleased]

### Changed
- **Breaking behavior**: mise 工具版本从 `latest` 改为固定版本号，确保可复现。
- Makefile 模块 target 改为自动生成，新增模块无需手动更新 `--skip` 列表。
- `MISE_FALLBACK_VERSION` 和 `UV_FALLBACK_VERSION` 集中到 `lib/common.sh`。

### Added
- `.github/renovate.json`：自动检测 mise 工具新版本并创建 PR。
- `.github/workflows/test.yml`：Ubuntu 22.04 / 24.04 / 26.04 矩阵测试。
- Dotfile manifest：运行时记录符号链接，确保卸载一致性。
- CI 自动检测 fallback 版本是否过期。

## [1.1.0] - 2026-05-14

### Added
- `opencode` 添加到 mise 工具列表。
- `verify.sh --strict` 模式。
- Docker 集成测试 (`test-docker.sh`)。
- 幂等性测试（第二次运行验证）。
- GHES 支持 (`GITHUB_SERVER_URL` 环境变量)。

### Changed
- `UV_PYTHON_VERSION` 默认从 3.13 改为 3.14。
- mise fallback 版本更新为 2026.5.14。
- 重构日志系统，新增 `warn_track` 和 `print_warnings_summary`。
- `verify.sh` 动态读取 mise 工具列表（不再硬编码）。

### Fixed
- `sudo` 缺失时错误信息更清晰。
- `_fetch_verified` 增加下载重试（curl `--retry 3 --retry-all-errors`）。

## [1.0.0] - 2026-Q1

### 初始版本
- 系统包 (apt)：build-essential, curl, wget, git, zsh, fzf 等。
- 开发工具 (mise)：node, go, ripgrep, fd, bat, lazygit 等。
- Python 工具链 (uv)：uv + Python。
- zsh 插件：autosuggestions, syntax-highlighting。
- Dotfiles 符号链接管理。
- `verify.sh` 健康检查。
- `uninstall.sh` 卸载。
