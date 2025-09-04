################################################################################
#
# hotkeyd
#
# https://github.com/vflyson/hotkeyd
#
################################################################################

HOTKEYD_VERSION = 0.4.6
HOTKEYD_TAG = e94e4ab50346e01ff1dcbf0f9d95bfe94a348b01
HOTKEYD_SITE = $(call github,jens-maus,hotkeyd,$(HOTKEYD_TAG))
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
