VSCODE_SETTING_DIR := ${HOME}/Library/Application Support/Code/User

.PHONY: init
init:
	ln -svf ${PWD}/settings.json "${VSCODE_SETTING_DIR}/settings.json" && \
	ln -svf ${PWD}/keybindings.json "${VSCODE_SETTING_DIR}/keybindings.json" && \
	while read -r line; do code --force --install-extension  "$$line"; done <extensions && \
	code --list-extensions > extensions


.PHONY: clean
clean:
	unlink "${VSCODE_SETTING_DIR}/settings.json" || true && \
	unlink "${VSCODE_SETTING_DIR}/keybindings.json" || true

.PHONY: format
format:
	bunx @biomejs/biome check --write settings.json
