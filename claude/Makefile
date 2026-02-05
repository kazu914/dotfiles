.PHONY: init
init:
	ln -svf ${PWD}/CLAUDE.md ${HOME}/.config/claude/CLAUDE.md

.PHONY: skills
skills:
	mkdir -p ${HOME}/.config/claude/skills && \
	for skill in ${PWD}/skills/*; do \
		ln -sfn "$$skill" $${HOME}/.config/claude/skills/$$(basename "$$skill"); \
	done

.PHONY: agents
agents:
	mkdir -p ${HOME}/.config/claude/agents && \
	for agent in ${PWD}/agents/*; do \
		ln -sfn "$$agent" $${HOME}/.config/claude/agents/$$(basename "$$agent"); \
	done

.PHONY: minimal
minimal: init

.PHONY: full
full: init skills agents

.PHONY: clean
clean:
	unlink ${HOME}/.config/claude/CLAUDE.md || true && \
	for skill in ${PWD}/skills/*; do \
		unlink $${HOME}/.config/claude/skills/$$(basename "$$skill") || true; \
	done
	for agent in ${PWD}/agents/*; do \
		unlink $${HOME}/.config/claude/agents/$$(basename "$$agent") || true; \
	done
