TPM_REPO   := ${HOME}/.tmux/plugins

.PHONY: init
init: ${TPM_REPO}
	ln -svf ${PWD}/00_tmux.conf ${HOME}/.tmux.conf

.PHONY: minimal
minimal: init

.PHONY: full
full: minimal

${TPM_REPO}:
	mkdir -p ${TPM_REPO} && \
	git clone https://github.com/tmux-plugins/tpm ${TPM_REPO}/tpm; \


.PHONY: clean
clean:
	rm -rf ${TPM_REPO} || true && \
	unlink ${HOME}/.tmux.conf
