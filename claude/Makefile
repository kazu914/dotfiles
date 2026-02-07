.PHONY: init
init:
	ln -svf ${PWD}/CLAUDE.md ${HOME}/.claude/CLAUDE.md

.PHONY: skills
skills:
	mkdir -p ${HOME}/.claude/skills && \
	for skill in ${PWD}/skills/*; do \
		ln -sfn "$$skill" $${HOME}/.claude/skills/$$(basename "$$skill"); \
	done

.PHONY: agents
agents:
	mkdir -p ${HOME}/.claude/agents && \
	for agent in ${PWD}/agents/*; do \
		ln -sfn "$$agent" $${HOME}/.claude/agents/$$(basename "$$agent"); \
	done

.PHONY: minimal
minimal: init

.PHONY: full
full: init skills agents

.PHONY: clean
clean:
	unlink ${HOME}/.claude/CLAUDE.md || true && \
	for skill in ${PWD}/skills/*; do \
		unlink $${HOME}/.claude/skills/$$(basename "$$skill") || true; \
	done
	for agent in ${PWD}/agents/*; do \
		unlink $${HOME}/.claude/agents/$$(basename "$$agent") || true; \
	done
