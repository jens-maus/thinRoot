################################################################################
#
# hotkeyd
#
# https://github.com/jens-maus/hotkeyd
#
################################################################################

HOTKEYD_VERSION = b35ba8173d9a95f0e8cc3be2d168124fc641fee6
HOTKEYD_SITE = $(call github,jens-maus,hotkeyd,$(HOTKEYD_VERSION))
HOTKEYD_LICENSE = GPL-3.0
HOTKEYD_LICENSE_FILES = LICENSE

define HOTKEYD_BUILD_CMDS
	$(MAKE) CC="$(TARGET_CC)" LD="$(TARGET_LD)" CFLAGS="$(TARGET_CFLAGS)" -C $(@D) all
endef

define HOTKEYD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/hotkeyd $(TARGET_DIR)/bin/
endef

define HOTKEYD_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(HOTKEYD_PKGDIR)/S60hotkeyd \
		$(TARGET_DIR)/etc/init.d/S60hotkeyd
endef

$(eval $(generic-package))
