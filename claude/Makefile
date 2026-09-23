MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
COMMON_DIR := $(abspath $(MAKEFILE_DIR)/../coding-agent)
CLAUDE_SOURCE := $(MAKEFILE_DIR)CLAUDE.md
CLAUDE_TARGET := $(HOME)/.claude/CLAUDE.md
COMMON_TARGET := $(HOME)/.claude/coding-agent
SKILLS_TARGET := $(HOME)/.claude/skills
LEGACY_AUDITOR_SOURCE := $(MAKEFILE_DIR)agents/task-auditor.md
LEGACY_AUDITOR_TARGET := $(HOME)/.claude/agents/task-auditor.md

.PHONY: init skills minimal full clean

init:
	@set -eu; \
	same_link() { [ -L "$$1" ] && [ "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$1")" = "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$2")" ]; }; \
	for pair in "$(CLAUDE_TARGET)|$(CLAUDE_SOURCE)" "$(COMMON_TARGET)|$(COMMON_DIR)"; do \
		target=$${pair%%|*}; source=$${pair#*|}; \
		if [ -e "$$target" ] || [ -L "$$target" ]; then \
			if ! same_link "$$target" "$$source"; then printf '%s\n' "refusing to replace existing item: $$target" >&2; exit 1; fi; \
		fi; \
	done; \
	mkdir -p "$(dir $(CLAUDE_TARGET))"; \
	for pair in "$(CLAUDE_TARGET)|$(CLAUDE_SOURCE)" "$(COMMON_TARGET)|$(COMMON_DIR)"; do \
		target=$${pair%%|*}; source=$${pair#*|}; \
		if [ ! -e "$$target" ] && [ ! -L "$$target" ]; then ln -s "$$source" "$$target"; fi; \
	done

skills:
	@set -eu; \
	same_link() { [ -L "$$1" ] && [ "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$1")" = "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$2")" ]; }; \
	seen=''; \
	for source in "$(MAKEFILE_DIR)skills"/* "$(COMMON_DIR)/skills"/*; do \
		[ -e "$$source" ] || continue; \
		name=$$(basename "$$source"); \
		case " $$seen " in *" $$name "*) printf '%s\n' "duplicate skill name: $$name" >&2; exit 1;; esac; \
		seen="$$seen $$name"; \
		target="$(SKILLS_TARGET)/$$name"; \
		if [ -e "$$target" ] || [ -L "$$target" ]; then \
			if ! same_link "$$target" "$$source"; then printf '%s\n' "refusing to replace existing item: $$target" >&2; exit 1; fi; \
		fi; \
	done; \
	mkdir -p "$(SKILLS_TARGET)"; \
	for source in "$(MAKEFILE_DIR)skills"/* "$(COMMON_DIR)/skills"/*; do \
		[ -e "$$source" ] || continue; \
		target="$(SKILLS_TARGET)/$$(basename "$$source")"; \
		if [ ! -e "$$target" ] && [ ! -L "$$target" ]; then ln -s "$$source" "$$target"; fi; \
	done

minimal: init
full: init skills

clean:
	@set -eu; \
	same_link() { [ -L "$$1" ] && [ "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$1")" = "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$2")" ]; }; \
	for pair in "$(CLAUDE_TARGET)|$(CLAUDE_SOURCE)" "$(COMMON_TARGET)|$(COMMON_DIR)" "$(LEGACY_AUDITOR_TARGET)|$(LEGACY_AUDITOR_SOURCE)"; do \
		target=$${pair%%|*}; source=$${pair#*|}; \
		if same_link "$$target" "$$source"; then rm "$$target"; fi; \
	done; \
	for source in "$(MAKEFILE_DIR)skills"/* "$(COMMON_DIR)/skills"/*; do \
		[ -e "$$source" ] || continue; \
		target="$(SKILLS_TARGET)/$$(basename "$$source")"; \
		if same_link "$$target" "$$source"; then rm "$$target"; fi; \
	done
