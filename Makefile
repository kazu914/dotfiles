SHELL=/bin/zsh

.PHONY: minimal
minimal: nvim_minimal zsh_minimal tmux

.PHONY: full
full: nvim_full zsh_full git node

.PHONY: clean
clean:
	cd nvim && make clean && \
	cd ../zsh && make clean && \
	cd ../git && make clean && \
	cd ../node && make clean && \

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

.PHONY: git
git:
	cd git && make init

.PHONY: node
node:
	cd node && make init
