GENERAL := $(PWD)/general
ENABLED := $(PWD)/enabled
PLUGINS := $(PWD)/plugins


.PHONY: minimal
minimal:
	mkdir -p $(ENABLED) && \
	cp -rsfv $(GENERAL)/*.vim $(ENABLED)
	

.PHONY: full
full: minimal
	cp -rsfv $(PLUGINS)/90_dein_init.vim $(ENABLED)

.PHONY: clean
clean:
	rm -rf $(ENABLED)

