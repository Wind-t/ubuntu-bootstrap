.PHONY: all verify test test-docker clean help

# ── 模块列表（单一定义，自动生成所有 target）────────────────────────────────
# 新增模块只需在此数组中加一个词。
MODULES := apt locale mise uv zsh-plugins dotfiles

# ── auto-generated: make apt, make mise, make dotfiles, … ─────────────────────
# 每个 target 运行 bootstrap.sh，跳过除自身之外的所有模块。
empty :=
space := $(empty) $(empty)
comma := ,

define single_module
$(1):
	@bash bootstrap.sh --skip=$(subst $(space),$(comma),$(filter-out $(1),$(MODULES)))
endef

$(foreach m,$(MODULES),$(eval $(call single_module,$(m))))
.PHONY: $(MODULES)

# ── 顶层 target ──────────────────────────────────────────────────────────────
all:
	@bash bootstrap.sh

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
	@echo "==> verify --strict"
	@bash verify.sh --strict
	@echo "==> test passed"

test-docker:
	@bash test-docker.sh

clean:
	@bash uninstall.sh --all --yes

help:
	@echo "make                  install everything"
	@for m in $(MODULES); do \
		printf 'make %-16s install %s only\n' "$$m" "$$m"; \
	done
	@echo "make verify           health check"
	@echo "make test             lint + syntax + dry-run + verify --strict"
	@echo "make test-docker      full Docker integration test"
	@echo "make clean            remove everything"
