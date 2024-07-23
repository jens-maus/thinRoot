################################################################################
#
# thinlinc
#
# https://www.cendio.com/thinlinc
#
################################################################################

THINLINC_VERSION = 4.17.0-3543
THINLINC_SITE = https://www.cendio.com/downloads/clients

ifeq ($(call qstrip,$(BR2_ARCH)),x86_64)
THINLINC_SOURCE = tl-$(THINLINC_VERSION)-client-linux-dynamic-x86_64.tar.gz
else ifeq ($(call qstrip,$(BR2_ARCH)),arm)
THINLINC_SOURCE = tl-$(THINLINC_VERSION)-client-linux-dynamic-armhf.tar.gz
endif

define THINLINC_INSTALL_TARGET_CMDS
	cp -R $(@D)/bin/* $(TARGET_DIR)/bin/
	cp -R $(@D)/etc/* $(TARGET_DIR)/etc/
	cp -R $(@D)/lib/* $(TARGET_DIR)/lib/
	ln -sf /bin/tlclient $(TARGET_DIR)/usr/bin/thinlinc
endef

$(eval $(generic-package))
