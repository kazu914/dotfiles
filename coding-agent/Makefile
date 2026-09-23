MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SKILLS_DIR := $(MAKEFILE_DIR)skills
TARGET_DIR := $(HOME)/.agents/skills

.PHONY: skills minimal full clean

skills:
	@set -eu; \
	same_link() { [ -L "$$1" ] && [ "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$1")" = "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$2")" ]; }; \
	for source in "$(SKILLS_DIR)"/*; do \
		[ -e "$$source" ] || continue; \
		target="$(TARGET_DIR)/$$(basename "$$source")"; \
		if [ -e "$$target" ] || [ -L "$$target" ]; then \
			if ! same_link "$$target" "$$source"; then printf '%s\n' "refusing to replace existing item: $$target" >&2; exit 1; fi; \
		fi; \
	done; \
	mkdir -p "$(TARGET_DIR)"; \
	for source in "$(SKILLS_DIR)"/*; do \
		[ -e "$$source" ] || continue; \
		target="$(TARGET_DIR)/$$(basename "$$source")"; \
		if [ ! -e "$$target" ] && [ ! -L "$$target" ]; then ln -s "$$source" "$$target"; fi; \
	done

minimal full: skills

clean:
	@set -eu; \
	same_link() { [ -L "$$1" ] && [ "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$1")" = "$$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$$2")" ]; }; \
	for source in "$(SKILLS_DIR)"/*; do \
		[ -e "$$source" ] || continue; \
		target="$(TARGET_DIR)/$$(basename "$$source")"; \
		if same_link "$$target" "$$source"; then rm "$$target"; fi; \
	done
