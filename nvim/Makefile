GENERAL := $(PWD)/general
ENABLED := $(PWD)/enabled
PLUGINS := $(PWD)/plugins

DEIN_REPO  := ${HOME}/.config/nvim/dein/repos/github.com/Shougo/dein.vim

.PHONY: init
init:
	mkdir -p ${HOME}/.config && \
	ln -sfnv ${PWD} ${HOME}/.config/nvim

.PHONY: minimal
minimal: init
	mkdir -p $(ENABLED) && \
	ln -sfv $(GENERAL)/00_setting.vim $(ENABLED)
	ln -sfv $(GENERAL)/01_mapping.vim $(ENABLED)
	

.PHONY: full
full: minimal ${DEIN_REPO}
	ln -sfv $(PLUGINS)/90_dein_init.vim $(ENABLED)

${DEIN_REPO}:
	mkdir -p ${DEIN_REPO} && \
	git clone https://github.com/Shougo/dein.vim.git ${DEIN_REPO}

.PHONY: clean
clean:
	unlink ${HOME}/.config/nvim || true && \
	rm -rf $(ENABLED) || true
