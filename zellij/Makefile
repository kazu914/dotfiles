.PHONY: init
init:
	mkdir -p ${HOME}/.config/zellij
	ln -svf ${PWD}/config.kdl ${HOME}/.config/zellij/config.kdl

.PHONY: clean
clean:
	unlink ${HOME}/.config/zellij/config.kdl || true
