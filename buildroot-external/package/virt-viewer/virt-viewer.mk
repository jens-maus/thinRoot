################################################################################
#
# virt-viewer
#
# https://gitlab.com/virt-viewer/virt-viewer
#
################################################################################

#VIRT_VIEWER_VERSION = v11.0
VIRT_VIEWER_VERSION = 82dbca46b605685ab354bf8cea7f2a2615132b39
VIRT_VIEWER_SITE = https://gitlab.com/virt-viewer/virt-viewer.git
VIRT_VIEWER_SITE_METHOD = git
#VIRT_VIEWER_DEPENDENCIES = xlib_libXScrnSaver
VIRT_VIEWER_LICENSE = GPL-2.0
VIRT_VIEWER_LICENSE_FILES = COPYING

VIRT_VIEWER_DEPENDENCIES = libgtk3 spice-gtk

define VIRT_VIEWER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/build/src/remote-viewer $(TARGET_DIR)/bin/
endef

$(eval $(meson-package))
