.PHONY: init
init:
	mkdir -p ${HOME}/.config/kitty
	ln -svf ${PWD}/kitty.conf ${HOME}/.config/kitty/kitty.conf

.PHONY: clean
clean:
	unlink ${HOME}/.config/kitty/kitty.conf || true
