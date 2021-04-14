.PHONY: init
init:
	${PWD}/install_packages.sh && \
	ln -svf ${PWD}/czrc ${HOME}/.czrc

.PHONY: clean
clean:
	${PWD}/uninstall_packages.sh && \
	unlink ${HOME}/.czrc || true 
