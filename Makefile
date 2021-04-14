SHELL=/bin/zsh


EXCLUSIONS := .git .gitignore
CANDIDATES := ${wildcard .??*}
DOTFILES   := ${filter-out ${EXCLUSIONS}, ${CANDIDATES}}

.PHONY: deploy init all npm_install 

.PHONY: minimal
minimal: nvim_minimal zsh_minimal tmux

.PHONY: full
full: nvim_full zsh_full tmux i3 git node

.PHONY: clean
clean:
	cd nvim && make clean && \
	cd ../zsh && make clean && \
	cd ../tmux && make clean && \
	cd ../i3 && make clean && \
	cd ../git && make clean && \
	cd ../node && make clean

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

.PHONY: i3
i3: 
	cd i3 && make init

.PHONY: tmux
tmux:
	cd tmux && make

.PHONY: git
git:
	cd git && make init

.PHONY: node
node:
	cd node && make init

all: deploy init

deploy:
	@${foreach val, ${DOTFILES}, ln -sfv ${abspath ${val}} ${HOME}/${val};} \

init: npm_install

npm_install: node
	${PWD}/npm/install_packages.sh
