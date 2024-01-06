tools=br-mount.sh br-umount.sh br-chroot.sh tools.sh utils.sh br-utils.sh

INSTALL_DIR=$(HOME)/bin

.PHONY: install

install:
	@cp $(tools) $(INSTALL_DIR)
