.PHONY: init
init:
	ln -svf ${PWD}/AGENTS.md ${HOME}/.codex/AGENTS.md

.PHONY: minimal
minimal: init

.PHONY: full
full: init

.PHONY: clean
clean:
	unlink ${HOME}/.claude/CLAUDE.md || true && \
