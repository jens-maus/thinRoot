################################################################################
#
# thinlinc
#
# https://www.cendio.com/thinlinc
#
################################################################################

THINLINC_VERSION = 4.12.0-6517
THINLINC_SOURCE = tl-$(THINLINC_VERSION)-client-linux-dynamic-x86_64.tar.gz
THINLINC_SITE = https://www.cendio.com/downloads/clients

define THINLINC_INSTALL_TARGET_CMDS
  cp -R $(@D)/bin/* $(TARGET_DIR)/bin/
  cp -R $(@D)/etc/* $(TARGET_DIR)/etc/
  cp -R $(@D)/lib/* $(TARGET_DIR)/lib/
  ln -sf /bin/tlclient $(TARGET_DIR)/usr/bin/thinlinc
endef

$(eval $(generic-package))
