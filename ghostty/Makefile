.PHONY: init
init:
	mkdir -p ${HOME}/.config/ghostty
	ln -svf ${PWD}/config ${HOME}/.config/ghostty/config

.PHONY: clean
clean:
	unlink ${HOME}/.config/ghostty/config || true
