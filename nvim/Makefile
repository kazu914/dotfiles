PACKER_REPO  := ${HOME}/.local/share/nvim/site/pack/packer/start/packer.nvim

.PHONY: init
init: ${PACKER_REPO}
	mkdir -p ${HOME}/.config && \
	ln -sfnv ${PWD} ${HOME}/.config/nvim

.PHONY: minimal
minimal: init

.PHONY: full
full: init

${PACKER_REPO}:
	git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim

.PHONY: clean
clean:
	unlink ${HOME}/.config/nvim || true && \
	rm -rf $(PACKER_REPO) || true
