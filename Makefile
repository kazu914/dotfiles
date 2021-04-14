SHELL=/bin/zsh

TPM_REPO   := ${HOME}/.tmux/plugins
NODE_BREW  := ${HOME}/.nodebrew/current/bin

EXCLUSIONS := .git .gitignore
CANDIDATES := ${wildcard .??*}
DOTFILES   := ${filter-out ${EXCLUSIONS}, ${CANDIDATES}}

.PHONY: deploy init all npm_install 

.PHONY: minimal
minimal: nvim_minimal zsh_minimal

.PHONY: full
full: nvim_full zsh_full

.PHONY: clean
clean:
	cd nvim && make clean && \
	cd ../zsh && make clean

.PHONY: nvim_minimal
nvim_minimal:
	cd nvim && make minimal

.PHONY: nvim_full
nvim_full:
	cd nvim && make full

.PHONY: zsh_minimal
zsh_minimal:
	cd zsh && make minimal

.PHONY: zsh_full
zsh_full:
	cd zsh && make full

all: deploy init

deploy:
	@${foreach val, ${DOTFILES}, ln -sfv ${abspath ${val}} ${HOME}/${val};} \
	ln -sfnv ${PWD}/i3 ${HOME}/.config


init: ${NODE_BREW} ${TPM_REPO}  npm_install


${NODE_BREW}:
	curl -L git.io/nodebrew | perl - setup && \
	${NODE_BREW}/nodebrew install v14.9.0 && \
	${NODE_BREW}/nodebrew use v14.9.0

${TPM_REPO}:
	mkdir -p ${TPM_REPO} && \
	git clone https://github.com/tmux-plugins/tpm ${TPM_REPO}/tpm; \



npm_install: ${NODE_BREW}
	${PWD}/npm/install_packages.sh
