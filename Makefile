.PHONY: help
help:
	@echo 'make install      install the dotfiles'
	@echo 'make setup        install a graphical environment'
	@echo 'make check        style check the files'

.PHONY: check
check:
	bash -n bash* install setup/*.sh setup/distros/*.sh setup/environments/*.sh
	./tools/style-check bash* install

.PHONY: install
install:
	./install

.PHONY: setup
setup:
	./setup/setup.sh
