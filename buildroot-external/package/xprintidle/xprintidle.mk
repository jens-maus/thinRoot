################################################################################
#
# xprintidle
#
# https://github.com/g0hl1n/xprintidle
#
################################################################################

XPRINTIDLE_VERSION = 0.2.2
XPRINTIDLE_TAG = 0.2.2
XPRINTIDLE_SITE = $(call github,g0hl1n,xprintidle,$(XPRINTIDLE_TAG))
XPRINTIDLE_LICENSE = GPL-2.0
XPRINTIDLE_LICENSE_FILES = COPYING

define XPRINTIDLE_BUILD_CMDS
	$(MAKE) CC="$(TARGET_CC)" LD="$(TARGET_LD)" CFLAGS="$(TARGET_CFLAGS)" -C $(@D) all
endef

define XPRINTIDLE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/xprintidle $(TARGET_DIR)/bin/
endef

$(eval $(autotools-package))
