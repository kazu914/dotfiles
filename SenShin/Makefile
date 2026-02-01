SENSHIN_SETTING_DIR := ${HOME}/Library/Containers/com.kazu914.SenShin/Data/Library/Application Support/com.kazu914.SenShin

.PHONY: init
init:
	mkdir -p "${SENSHIN_SETTING_DIR}"
	ln -svf ${PWD}/settings.yaml "${SENSHIN_SETTING_DIR}/settings.yaml"

.PHONY: clean
clean:
	unlink "${SENSHIN_SETTING_DIR}/settings.yaml" || true
