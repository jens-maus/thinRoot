################################################################################
#
# setrootpix
#
################################################################################

SETROOTPIX_VERSION = 0.2.0
SETROOTPIX_SITE = $(BR2_EXTERNAL_THINROOT_PATH)/package/setrootpix
SETROOTPIX_SITE_METHOD = local
SETROOTPIX_LICENSE = Apache-2.0
SETROOTPIX_LICENSE_FILES = LICENSE
SETROOTPIX_DEPENDENCIES = xlib_libX11

define SETROOTPIX_BUILD_CMDS
	$(MAKE) CC="$(TARGET_CC)" LD="$(TARGET_LD)" CFLAGS="$(TARGET_CFLAGS)" -C $(@D) all
endef

define SETROOTPIX_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/setrootpix $(TARGET_DIR)/usr/bin
endef

$(eval $(generic-package))
