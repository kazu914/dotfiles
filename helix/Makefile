.PHONY: init
init:
	mkdir -p ${HOME}/.config/helix
	ln -svf ${PWD}/config.toml ${HOME}/.config/helix/config.toml

.PHONY: clean
clean:
	unlink ${HOME}/.config/helix/config.toml || true
