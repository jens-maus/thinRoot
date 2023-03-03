################################################################################
#
# xprintidle
#
# https://github.com/g0hl1n/xprintidle
#
################################################################################

XPRINTIDLE_VERSION = 0.2.5
XPRINTIDLE_SITE = $(call github,g0hl1n,xprintidle,$(XPRINTIDLE_VERSION))
XPRINTIDLE_DEPENDENCIES = xlib_libXScrnSaver
XPRINTIDLE_LICENSE = GPL-2.0
XPRINTIDLE_LICENSE_FILES = COPYING

define XPRINTIDLE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/build/xprintidle $(TARGET_DIR)/bin/
endef

$(eval $(meson-package))
