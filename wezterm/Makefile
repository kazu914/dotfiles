.PHONY: init
init:
	mkdir -p ${HOME}/.config/wezterm
	ln -svf ${PWD}/wezterm.lua ${HOME}/.config/wezterm/wezterm.lua
	ln -svf ${PWD}/utils.lua ${HOME}/.config/wezterm/utils.lua

.PHONY: clean
clean:
	unlink ${HOME}/.config/wezterm/wezterm.lua || true
