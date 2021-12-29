.PHONY: init
init:
	ls *.lua | xargs -I{} ln -svf ${PWD}/{} ${HOME}/.hammerspoon/{}

.PHONY: clean
clean:
	ls *.lua | xargs -I{} unlink ${HOME}/.hammerspoon/{}
