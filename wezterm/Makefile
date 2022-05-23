.PHONY: init
init:
	mkdir -p ${HOME}/.config/wezterm
	ln -svf ${PWD}/wezterm.lua ${HOME}/.config/wezterm/wezterm.yml

.PHONY: clean
clean:
	unlink ${HOME}/.config/wezterm/wezterm.lua || true
