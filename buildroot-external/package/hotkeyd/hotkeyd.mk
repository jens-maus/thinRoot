################################################################################
#
# hotkeyd
#
# https://github.com/vflyson/hotkeyd
#
################################################################################

HOTKEYD_VERSION = 0.4.4
HOTKEYD_TAG = 0ee8b2ae1344c9c8bedd0f91ebda0b389271a6d3
HOTKEYD_SITE = $(call github,jens-maus,hotkeyd,$(HOTKEYD_TAG))
HOTKEYD_LICENSE = GPL-3.0
HOTKEYD_LICENSE_FILES = LICENSE
HOTKEYD_INSTALL_TARGET = YES

define HOTKEYD_BUILD_CMDS
  $(MAKE) CC="$(TARGET_CC)" LD="$(TARGET_LD)" CFLAGS="$(TARGET_CFLAGS)" -C $(@D) all
endef

define HOTKEYD_INSTALL_TARGET_CMDS
  $(INSTALL) -D -m 0755 $(@D)/hotkeyd $(TARGET_DIR)/bin/
endef

$(eval $(generic-package))
