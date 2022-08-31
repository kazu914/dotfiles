.PHONY: init
init:
	mkdir -p ${HOME}/.config/alacritty
	ln -svf ${PWD}/alacritty.yml ${HOME}/.config/alacritty/alacritty.yml

.PHONY: clean
clean:
	unlink ${HOME}/.config/alacritty/alacritty.yml || true
