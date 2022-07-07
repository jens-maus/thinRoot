################################################################################
#
# numlockx
#
# https://github.com/rg3/numlockx
#
################################################################################

NUMLOCKX_VERSION = 1.2
NUMLOCKX_TAG = 1.2
NUMLOCKX_SITE = $(call github,rg3,numlockx,$(NUMLOCKX_TAG))
NUMLOCKX_LICENSE = MIT
NUMLOCKX_LICENSE_FILES = LICENSE

define NUMLOCKX_BUILD_CMDS
	$(MAKE) CC="$(TARGET_CC)" LD="$(TARGET_LD)" CFLAGS="$(TARGET_CFLAGS)" -C $(@D) all
endef

define NUMLOCKX_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/numlockx $(TARGET_DIR)/bin/
endef

$(eval $(autotools-package))
