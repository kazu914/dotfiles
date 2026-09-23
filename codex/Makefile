MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
COMMON_DIR := $(abspath $(MAKEFILE_DIR)/../coding-agent)
AGENTS_SOURCE := $(COMMON_DIR)/AGENTS.md
LEGACY_AGENTS_SOURCE := $(MAKEFILE_DIR)AGENTS.md
AGENTS_TARGET := $(HOME)/.codex/AGENTS.md

.PHONY: init skills minimal full clean

init:
	@set -eu; \
	same_link() { [ -L "$$1" ] && [ "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$1")" = "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$2")" ]; }; \
	if [ -e "$(AGENTS_TARGET)" ] || [ -L "$(AGENTS_TARGET)" ]; then \
		if same_link "$(AGENTS_TARGET)" "$(AGENTS_SOURCE)"; then :; \
		elif same_link "$(AGENTS_TARGET)" "$(LEGACY_AGENTS_SOURCE)"; then rm "$(AGENTS_TARGET)"; ln -s "$(AGENTS_SOURCE)" "$(AGENTS_TARGET)"; \
		else printf '%s\n' "refusing to replace existing item: $(AGENTS_TARGET)" >&2; exit 1; fi; \
	else \
		mkdir -p "$(dir $(AGENTS_TARGET))"; \
		ln -s "$(AGENTS_SOURCE)" "$(AGENTS_TARGET)"; \
	fi

skills:
	@$(MAKE) -C "$(COMMON_DIR)" skills

minimal: init
full: init skills

clean:
	@set -eu; \
	same_link() { [ -L "$$1" ] && [ "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$1")" = "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$2")" ]; }; \
	if same_link "$(AGENTS_TARGET)" "$(AGENTS_SOURCE)" || same_link "$(AGENTS_TARGET)" "$(LEGACY_AGENTS_SOURCE)"; then rm "$(AGENTS_TARGET)"; fi
	@$(MAKE) -C "$(COMMON_DIR)" clean
