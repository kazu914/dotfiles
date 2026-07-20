SHELL := /bin/zsh

MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPOSITORY := kazu914/local-file-server
INSTALL_DIR ?= ${HOME}/.local/bin
BINARY := ${INSTALL_DIR}/lfs
CONFIG_DIR ?= ${HOME}/.config/local-file-server
CONFIG := ${CONFIG_DIR}/config.json
CONFIG_SOURCE := ${MAKEFILE_DIR}/config.json
ASSET_PATTERN := local-file-server_*_darwin_universal
CHECKSUM_PATTERN := ${ASSET_PATTERN}.sha256

.PHONY: init install config
init: install config

install:
	@set -euo pipefail; \
	temporary_directory="$$(mktemp -d)"; \
	trap 'rm -rf "$$temporary_directory"' EXIT; \
	gh release download --repo "${REPOSITORY}" --pattern "${ASSET_PATTERN}" --dir "$$temporary_directory"; \
	gh release download --repo "${REPOSITORY}" --pattern "${CHECKSUM_PATTERN}" --dir "$$temporary_directory"; \
	asset="$$(find "$$temporary_directory" -maxdepth 1 -type f -name "${ASSET_PATTERN}" -print -quit)"; \
	checksum="$$(find "$$temporary_directory" -maxdepth 1 -type f -name "${CHECKSUM_PATTERN}" -print -quit)"; \
	test -n "$$asset" -a -n "$$checksum"; \
	(cd "$$temporary_directory" && shasum -a 256 -c "$$(basename "$$checksum")"); \
	mkdir -p "${INSTALL_DIR}"; \
	install -m 755 "$$asset" "${BINARY}.tmp"; \
	mv -f "${BINARY}.tmp" "${BINARY}"

config: ${CONFIG_SOURCE}
	@mkdir -p "${CONFIG_DIR}"
	ln -sfn "$<" "${CONFIG}"
