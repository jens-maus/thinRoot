################################################################################
#
# libxosd / xosd
#
################################################################################

XOSD_VERSION = 2.2.14
XOSD_SITE = https://downloads.sourceforge.net/project/libxosd/libxosd/xosd-$(XOSD_VERSION)
XOSD_LICENSE = GPL-2.0-or-later
XOSD_LICENSE_FILES = COPYING
XOSD_DEPENDENCIES = xlib_libX11 xlib_libXext

# remove unnecessary stuff
define XOSD_REMOVE_DATA
	$(RM) -r $(TARGET_DIR)/usr/share/xosd
	$(RM) -r $(TARGET_DIR)/usr/bin/xosd-config
endef
XOSD_POST_INSTALL_TARGET_HOOKS += XOSD_REMOVE_DATA

$(eval $(autotools-package))
