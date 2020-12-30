SHELL=/bin/zsh

DEIN_REPO  := ${HOME}/.config/nvim/dein/repos/github.com/Shougo/dein.vim
TPM_REPO   := ${HOME}/.tmux/plugins
NODE_BREW  := ${HOME}/.nodebrew/current/bin

EXCLUSIONS := .git .gitignore
CANDIDATES := ${wildcard .??*}
DOTFILES   := ${filter-out ${EXCLUSIONS}, ${CANDIDATES}}

.PHONY: deploy init all npm_install

all: deploy init

deploy:
	@${foreach val, ${DOTFILES}, ln -sfv ${abspath ${val}} ${HOME}/${val};} \
	mkdir -p ${HOME}/.config && ln -sfnv ${PWD}/nvim ${HOME}/.config/nvim


init: ${NODE_BREW} ${TPM_REPO} ${DEIN_REPO} npm_install


${NODE_BREW}:
	curl -L git.io/nodebrew | perl - setup && \
	${NODE_BREW}/nodebrew install v14.9.0 && \
	${NODE_BREW}/nodebrew use v14.9.0

${TPM_REPO}:
	mkdir -p ${TPM_REPO} && \
	git clone https://github.com/tmux-plugins/tpm ${TPM_REPO}/tpm; \

${DEIN_REPO}:
	mkdir -p ${DEIN_REPO} && \
	git clone https://github.com/Shougo/dein.vim.git ${DEIN_REPO}; \


npm_install: ${NODE_BREW}
	${PWD}/npm/install_packages.sh
