################################################################################
#
# xfconf
#
################################################################################

XFCONF_VERSION = 4.20.0
XFCONF_SOURCE = xfconf-$(XFCONF_VERSION).tar.bz2
XFCONF_SITE = https://archive.xfce.org/src/xfce/xfconf/4.20
XFCONF_LICENSE = GPL-2.0+
XFCONF_LICENSE_FILES = COPYING

XFCONF_DEPENDENCIES = \
	host-pkgconf host-gettext host-libglib2 \
	dbus libxml2 libxfce4util

XFCONF_CONF_ENV += GDBUS_CODEGEN=$(HOST_DIR)/bin/gdbus-codegen

XFCONF_CONF_OPTS = \
	--disable-debug \
	--disable-gtk-doc

# Ensure the D-Bus daemon can be spawned by the session and the service is present
XFCONF_INSTALL_STAGING = YES

$(eval $(autotools-package))
