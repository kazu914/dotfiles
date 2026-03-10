.PHONY: init
init:
	mkdir -p ${HOME}/.config/my-terminal
	ln -svf ${PWD}/config.toml ${HOME}/.config/my-terminal/config.toml

.PHONY: clean
clean:
	unlink ${HOME}/.config/my-terminal/config.toml || true
