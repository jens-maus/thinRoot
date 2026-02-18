################################################################################
#
# libwnck
#
################################################################################

LIBWNCK_VERSION = 43.3
LIBWNCK_SOURCE = libwnck-$(LIBWNCK_VERSION).tar.xz
LIBWNCK_SITE = https://download.gnome.org/sources/libwnck/43
LIBWNCK_LICENSE = LGPL-2.1+
LIBWNCK_LICENSE_FILES = COPYING

LIBWNCK_DEPENDENCIES = \
	host-pkgconf \
	libgtk3 \
	xlib_libXext \
	xlib_libXres

LIBWNCK_CONF_OPTS = \
	-Dintrospection=disabled \
	-Dgtk_doc=false

LIBWNCK_INSTALL_STAGING = YES

$(eval $(meson-package))
