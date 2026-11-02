APP_HOME ?= ${HOME}/.config/herdr-app

# The app home is created by Herdr on first run; run `make init` after that.
# Only personal files are tracked: settings, keys, the cloned layout, the
# catppuccin theme and the two custom mods. App-written state (view.json,
# shared.json, installed.json, layouts/.state, jsconfig.json, *.d.ts inside
# mods) stays out of the repo. Herdr writes settings.json and the shown
# layout through these symlinks, so the repo follows live changes.

.PHONY: init
init:
	mkdir -p ${APP_HOME}/themes ${APP_HOME}/layouts
	ln -svf ${CURDIR}/keys.json ${APP_HOME}/keys.json
	ln -svf ${CURDIR}/settings.json ${APP_HOME}/settings.json
	ln -svf ${CURDIR}/themes/catppuccin.json ${APP_HOME}/themes/catppuccin.json
	ln -svf ${CURDIR}/layouts/my-main.json ${APP_HOME}/layouts/my-main.json
	mkdir -p ${APP_HOME}/mods/my-picker ${APP_HOME}/mods/tab-actions
	ln -svf ${CURDIR}/mods/my-picker/main.js ${APP_HOME}/mods/my-picker/main.js
	ln -svf ${CURDIR}/mods/my-picker/mod.json ${APP_HOME}/mods/my-picker/mod.json
	ln -svf ${CURDIR}/mods/tab-actions/main.js ${APP_HOME}/mods/tab-actions/main.js
	ln -svf ${CURDIR}/mods/tab-actions/mod.json ${APP_HOME}/mods/tab-actions/mod.json

.PHONY: clean
clean:
	for f in keys.json settings.json themes/catppuccin.json layouts/my-main.json \
		mods/my-picker/main.js mods/my-picker/mod.json \
		mods/tab-actions/main.js mods/tab-actions/mod.json; do \
		if [ -L ${APP_HOME}/$$f ]; then unlink ${APP_HOME}/$$f; fi; \
	done
