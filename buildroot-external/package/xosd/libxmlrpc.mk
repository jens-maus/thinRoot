################################################################################
#
# libxosd / xosd
#
################################################################################

# 2.2.15 (code/libxosd-code@r634)
XOSD_VERSION = r634
XOSD_SITE = https://svn.code.sf.net/p/libxosd/code/libxosd-code
XOSD_SITE_METHOD = svn
XOSD_LICENSE = GPLv2
XOSD_LICENSE_FILES = COPYING
XOSD_INSTALL_STAGING = YES
XOSD_DEPENDENCIES = host-autoconf
XOSD_MAKE = $(MAKE1)

# Using autoconf, not automake, so we cannot use AUTORECONF = YES.
define XOSD_RUN_AUTOCONF
	cd $(@D); $(AUTOCONF)
endef

XOSD_PRE_CONFIGURE_HOOKS += XOSD_RUN_AUTOCONF

$(eval $(autotools-package))
