################################################################################
#
# libxosd / xosd
#
################################################################################

XOSD_VERSION = 2.2.14
XOSD_SOURCE = xosd-$(XOSD_VERSION).tar.gz
XOSD_SITE = http://sourceforge.net/projects/libxosd/files
XOSD_LICENSE = GPL-2.0
XOSD_LICENSE_FILES = COPYING
#XOSD_DEPENDENCIES = host-autoconf

# remove unnecessary stuff
define XOSD_REMOVE_DATA
	$(RM) -r $(TARGET_DIR)/usr/share/xosd
	$(RM) -r $(TARGET_DIR)/usr/bin/xosd-config
endef
XOSD_POST_INSTALL_TARGET_HOOKS += XOSD_REMOVE_DATA

$(eval $(autotools-package))
