NODE_BREW  := ${HOME}/.nodebrew/current/bin

.PHONY: init
init: ${NODE_BREW}

${NODE_BREW}:
	curl -L git.io/nodebrew | perl - setup && \
	${NODE_BREW}/nodebrew install v16 && \
	${NODE_BREW}/nodebrew use v16

.PHONY: clean
clean:
	rm -rf ${HOME}/.nodebrew || true
