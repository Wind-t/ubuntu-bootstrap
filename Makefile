.PHONY: all apt locale mise uv zsh-plugins dotfiles verify test test-docker clean help

all:
	@bash bootstrap.sh

apt:            ; @bash bootstrap.sh --skip=locale,mise,uv,zsh-plugins,dotfiles
locale:         ; @bash bootstrap.sh --skip=apt,mise,uv,zsh-plugins,dotfiles
mise:           ; @bash bootstrap.sh --skip=apt,locale,uv,zsh-plugins,dotfiles
uv:             ; @bash bootstrap.sh --skip=apt,locale,mise,zsh-plugins,dotfiles
zsh-plugins:    ; @bash bootstrap.sh --skip=apt,locale,mise,uv,dotfiles
dotfiles:       ; @bash bootstrap.sh --skip=apt,locale,mise,uv,zsh-plugins

verify:
	@bash verify.sh

test:
	@echo "==> shellcheck"
	@shellcheck --severity=warning bootstrap.sh lib/*.sh verify.sh uninstall.sh test-docker.sh 2>&1
	@echo "==> bash syntax"
	@bash -n bootstrap.sh && bash -n verify.sh && bash -n uninstall.sh
	@for f in lib/*.sh; do bash -n "$$f" || exit 1; done
	@echo "==> dry-run"
	@bash bootstrap.sh --dry-run
	@echo "==> test passed"

test-docker:
	@bash test-docker.sh

clean:
	@bash uninstall.sh --all --yes

help:
	@echo "make                  install everything"
	@echo "make apt              system packages only"
	@echo "make mise             dev tools only"
	@echo "make verify           health check"
	@echo "make test             lint + syntax + dry-run"
	@echo "make test-docker      full Docker integration test"
	@echo "make clean            remove everything"
