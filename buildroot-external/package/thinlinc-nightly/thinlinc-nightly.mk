################################################################################
#
# thinlinc-nightly
#
# https://www.cendio.com/thinlinc
#
################################################################################

THINLINC_NIGHTLY_VERSION = 4.20.0post
THINLINC_NIGHTLY_SITE = https://www.cendio.com/downloads/nightly
THINLINC_NIGHTLY_SOURCE = tl-nightly-clients.zip

ifeq ($(call qstrip,$(BR2_ARCH)),x86_64)
THINLINC_NIGHTLY_SUBDIR = tl-$(THINLINC_NIGHTLY_VERSION)-*-client-linux-dynamic-x86_64
else ifeq ($(call qstrip,$(BR2_ARCH)),aarch64)
THINLINC_NIGHTLY_SUBDIR = tl-$(THINLINC_NIGHTLY_VERSION)-*-client-linux-dynamic-armhf
else ifeq ($(call qstrip,$(BR2_ARCH)),arm)
THINLINC_NIGHTLY_SUBDIR = tl-$(THINLINC_NIGHTLY_VERSION)-*-client-linux-dynamic-armhf
endif

define THINLINC_NIGHTLY_EXTRACT_CMDS
	rm -rf $(@D)/*
	mkdir -p $(@D)
	$(UNZIP) -q $(THINLINC_NIGHTLY_DL_DIR)/$(THINLINC_NIGHTLY_SOURCE) -d $(@D)
endef

define THINLINC_NIGHTLY_INSTALL_TARGET_CMDS
	cp -Rv $(@D)/tl-*-clients/client-linux-dynamic/$(THINLINC_NIGHTLY_SUBDIR)/bin/* $(TARGET_DIR)/bin/
	cp -Rv $(@D)/tl-*-clients/client-linux-dynamic/$(THINLINC_NIGHTLY_SUBDIR)/etc/* $(TARGET_DIR)/etc/
	cp -Rv $(@D)/tl-*-clients/client-linux-dynamic/$(THINLINC_NIGHTLY_SUBDIR)/lib/* $(TARGET_DIR)/lib/
	ln -sf /bin/tlclient $(TARGET_DIR)/usr/bin/thinlinc
endef

$(eval $(generic-package))
