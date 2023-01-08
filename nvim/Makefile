.PHONY: init
init:
	mkdir -p ${HOME}/.config && \
	ln -sfnv ${PWD} ${HOME}/.config/nvim

.PHONY: minimal
minimal: init

.PHONY: full
full: init

.PHONY: clean
clean:
	unlink ${HOME}/.config/nvim || true
