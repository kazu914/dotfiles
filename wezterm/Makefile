.PHONY: init
init:
	mkdir -p ${HOME}/.config/wezterm
	ln -svf ${PWD}/wezterm.lua ${HOME}/.config/wezterm/wezterm.lua
	ln -svf ${PWD}/utils.lua ${HOME}/.config/wezterm/utils.lua
	ln -svf ${PWD}/key_bindings.lua ${HOME}/.config/wezterm/key_bindings.lua
	ln -svf ${PWD}/mouse_bindings.lua ${HOME}/.config/wezterm/mouse_bindings.lua
	ln -svf ${PWD}/ui_components.lua ${HOME}/.config/wezterm/ui_components.lua
	ln -svf ${PWD}/workspace_management.lua ${HOME}/.config/wezterm/workspace_management.lua

.PHONY: clean
clean:
	unlink ${HOME}/.config/wezterm/wezterm.lua || true
