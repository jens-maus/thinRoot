################################################################################
#
# xfwm4
#
################################################################################

XFWM4_VERSION = 4.20.0
XFWM4_SOURCE = xfwm4-$(XFWM4_VERSION).tar.bz2
XFWM4_SITE = https://archive.xfce.org/src/xfce/xfwm4/4.20
XFWM4_LICENSE = GPL-2.0+
XFWM4_LICENSE_FILES = COPYING

XFWM4_DEPENDENCIES = \
	host-pkgconf \
	libgtk3 \
	xfconf \
	libxfce4ui \
	libwnck \
	xlib_libXext \
	xlib_libXres \
	xlib_libXrandr \
	xlib_libXcomposite \
	xlib_libXdamage \
	xlib_libXfixes \
	xlib_libXi \
	xlib_libXres

XFWM4_CONF_OPTS = \
	--disable-static \
	--disable-debug \
	--disable-gtk-doc \
	--disable-introspection \
	--disable-maintainer-mode \
	--disable-vala \
	--disable-settings \
	--disable-settings-dialogs \
	--disable-xsync \
	--disable-xpresent

ifeq ($(BR2_PACKAGE_XFWM4_COMPOSITOR),y)
XFWM4_CONF_OPTS += --enable-compositor
else
XFWM4_CONF_OPTS += --disable-compositor
endif

# ---------------------------------------------------------------------------
# Minimal build: remove "settings-dialogs" from top-level SUBDIRS.
# We must not override SUBDIRS globally (breaks nested directories like icons/).
# So we patch only the *top-level* Makefile after configure.
# ---------------------------------------------------------------------------
define XFWM4_DROP_SETTINGS_DIALOGS
	# Top-level Makefile contains a "SUBDIRS =" assignment. Remove settings-dialogs only.
	$(SED) 's/[[:space:]]settings-dialogs[[:space:]]/ /g' $(@D)/Makefile
	$(SED) 's/[[:space:]]settings-dialogs$$//g' $(@D)/Makefile
endef
XFWM4_POST_CONFIGURE_HOOKS += XFWM4_DROP_SETTINGS_DIALOGS

$(eval $(autotools-package))
