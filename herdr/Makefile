.PHONY: tab-actions-build
tab-actions-build:
	cargo build --manifest-path ${CURDIR}/plugins/tab-actions/Cargo.toml --release

.PHONY: init
init: tab-actions-build
	mkdir -p ${HOME}/.config/herdr
	ln -svf ${CURDIR}/config.toml ${HOME}/.config/herdr/config.toml
	if command -v herdr >/dev/null 2>&1; then \
		herdr plugin link ${CURDIR}/plugins/tab-actions; \
	else \
		echo "skip linking Herdr plugins: herdr command not found"; \
	fi

.PHONY: clean
clean:
	if command -v herdr >/dev/null 2>&1; then \
		herdr plugin unlink kazu914.tab-actions || true; \
	fi
	unlink ${HOME}/.config/herdr/config.toml || true
