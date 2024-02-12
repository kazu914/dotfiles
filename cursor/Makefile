CURSOR_SETTING_DIR := ${HOME}/Library/Application Support/Cursor/User

.PHONY: init
init:
	ln -svf ${PWD}/settings.json "${CURSOR_SETTING_DIR}/settings.json" && \
	ln -svf ${PWD}/keybindings.json "${CURSOR_SETTING_DIR}/keybindings.json" && \
	while read -r line; do cursor --force --install-extension  "$$line"; done < extensions && \
	cursor --list-extensions > extensions


.PHONY: clean
clean:
	unlink "${CURSOR_SETTING_DIR}/settings.json" || true && \
	unlink "${CURSOR_SETTING_DIR}/keybindings.json" || true

.PHONY: sync
sync:
	cursor --list-extensions > extensions