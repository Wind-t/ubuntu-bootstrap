# AGENTS.md — ubuntu-bootstrap

Shell-script Ubuntu dev environment bootstrap. ~500 lines core (~900 total with verify + uninstall). Personal tool, no PR workflow.

**Supported Ubuntu versions:** 22.04, 24.04, 26.04 (and newer). Version check in `bootstrap.sh` warns for <22.04, passes for ≥22.

## Commands

```bash
make test       # shellcheck all .sh + verify --strict (always run before committing)
make            # full bootstrap (≈ bash bootstrap.sh)
make verify     # health check only (no lint)
make clean      # full uninstall
make help       # list all targets
```

Docker integration test: `docker build -t test . && docker run --rm test`
(Set `GITHUB_TOKEN` to avoid API rate limits — `test-docker.sh` auto-detects and passes it.)

## Module rules (non-negotiable)

- Every `.sh` file starts with `#!/usr/bin/env bash` + `set -euo pipefail`. Never remove.
- Each `lib/setup-*.sh` is **source-only** — declares one `setup_*` function. Nothing executes on source.
- Every `setup_*` function **must** call `set_step "description"` as its first real statement. This feeds `bootstrap_trap` error tracing.
- Modules that reference `$SCRIPT_DIR` (set by `bootstrap.sh` before sourcing) **must** include a guard: `: "${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"`. This allows standalone sourcing for debugging.
- **Never** use `echo`/`printf` directly for user-facing output. Use the logging functions: `log` (info), `success` (done), `warn` (non-fatal), `fail` (abort), `die` (fatal with code).
- **Idempotency is mandatory.** Every setup function must be safe to re-run. Check before acting (e.g. `command -v`, `dpkg -s`, `[ -L "$dst" ]`).
- **Critical tool install failures must abort.** `setup_mise` uses `fail` (not `warn_track`) when `mise install` exits non-zero — 19 dev tools missing is not a warning.

## Dependency chain

```
bootstrap.sh → lib/common.sh → lib/setup-*.sh
               (log, fail, backup_then_link, is_ci, is_interactive_skip, set_step, ...)
```

`common.sh` is sourced once in `bootstrap.sh`. All setup modules inherit its functions. New modules go in `lib/` and are sourced + called from `bootstrap.sh`.

## Dotfiles: symlink philosophy

`config/` files are **symlinked** into `$HOME`. Editing `~/.zshrc` edits `config/.zshrc`. This is by design — don't "fix" it.

Use `backup_then_link src dst` (from common.sh) for all symlink creation. It handles: already-correct links (skip), existing files (backup with `.bak.TIMESTAMP`), missing parent dirs (auto-create). Never use raw `ln`.

**Dotfile destination list** lives in `UB_DOTFILE_DESTS` (common.sh) — the single source of truth shared by `setup-dotfiles.sh` and `uninstall.sh`. Adding a dotfile means: (a) adding the `backup_then_link` call to `setup-dotfiles.sh`, (b) adding the destination path to `UB_DOTFILE_DESTS`.

## Configuration

- `config/mise.config.toml` — single source of truth for dev tools. `verify.sh` reads it dynamically via `mise ls --json`. Adding a tool here auto-adds it to verification.
- `config/zsh/*.zsh` — loaded in numeric order by `.zshrc`. Add personal modules with higher numbers (e.g. `11-local.zsh`). Rename to `.disabled` to skip.
- `BIN_MAP` in `verify.sh` maps tool names to binaries when they differ (e.g. `ripgrep` → `rg`, `tealdeer` → `tldr`).

## Environment variables

| Variable | Effect |
|----------|--------|
| `SKIP_INTERACTIVE=1` | Skip chsh and prompts (CI/Docker) |
| `QUIET=1` | Suppress all but warnings and errors |
| `NO_COLOR=1` | Disable ANSI colors (pipes, logs) |
| `UV_PYTHON_VERSION` | Python version for uv (default `3.14`) |

## Linting

Only ShellCheck. `bash-language-server` is **not installed** and not expected. Run `shellcheck *.sh lib/*.sh` or just `make test`.

## Download resilience

`_fetch_verified` in `common.sh` downloads with `curl --retry 3 --retry-all-errors`. This covers transient failures (timeouts, partial transfers, connection resets) for both mise and uv binary downloads. The `mise install` step (19 tools via aqua backend) does NOT have the same retry — if it fails, the build aborts (see module rules above).
