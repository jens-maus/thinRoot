################################################################################
#
# libxfce4util
#
################################################################################

LIBXFCE4UTIL_VERSION = 4.20.1
LIBXFCE4UTIL_SOURCE = libxfce4util-$(LIBXFCE4UTIL_VERSION).tar.bz2
LIBXFCE4UTIL_SITE = https://archive.xfce.org/src/xfce/libxfce4util/4.20
LIBXFCE4UTIL_LICENSE = LGPL-2.1+
LIBXFCE4UTIL_LICENSE_FILES = COPYING

LIBXFCE4UTIL_INSTALL_STAGING = YES

LIBXFCE4UTIL_DEPENDENCIES = host-pkgconf host-gettext libglib2

LIBXFCE4UTIL_CONF_OPTS = \
	--disable-debug \
	--disable-gtk-doc

$(eval $(autotools-package))
