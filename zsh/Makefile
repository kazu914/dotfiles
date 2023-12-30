ENABLED := ${PWD}/enabled

.PHONY: init
init:
	ln -svf ${PWD}/00_zshrc ${HOME}/.zshrc

.PHONY: minimal
minimal: init
	mkdir -p ${PWD}/enabled && \
	ln -svf ${PWD}/01_config.zsh ${ENABLED} && \
	ln -svf ${PWD}/03_plugins.zsh ${ENABLED} && \
	ln -svf ${PWD}/04_zoxide.zsh ${ENABLED} && \
	ln -svf ${PWD}/20_fzf_basic.zsh ${ENABLED} && \
	ln -svf ${PWD}/21_fzf_git.zsh ${ENABLED} && \
	ln -svf ${PWD}/29_fzf_others.zsh ${ENABLED} && \
	ln -svf ${PWD}/05_starship.toml ${HOME}/.config/starship.toml
	ln -svf ${PWD}/99_aliases.zsh ${ENABLED}

.PHONY: full
full: minimal
	@true

.PHONY: clean
clean:
	unlink ${HOME}/.zshrc || true && \
	unlink ${HOME}/.config/starship.toml || true && \
	rm -rf $(ENABLED) || true
