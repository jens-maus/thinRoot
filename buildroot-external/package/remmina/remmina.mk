################################################################################
#
# remmina
#
# https://gitlab.com/Remmina/Remmina
#
################################################################################

REMMINA_VERSION = v1.4.18
REMMINA_SOURCE = Remmina-$(REMMINA_VERSION).tar.gz
REMMINA_SITE = https://gitlab.com/Remmina/Remmina/-/archive/$(REMMINA_VERSION)
REMMINA_LICENSE = GPLv2+ with OpenSSL exception
REMMINA_LICENSE_FILES = COPYING LICENSE LICENSE.OpenSSL

REMMINA_CONF_OPTS = \
	-DWITH_ICON_CACHE=ON \
	-DWITH_CUPS=OFF \
	-DWITH_SPICE=OFF \
	-DWITH_WAYLAND=OFF \
	-DWITH_PULSE=ON \
	-DWITH_AVAHI=OFF \
	-DWITH_APPINDICATOR=OFF \
	-DWITH_GNOMEKEYRING=OFF \
	-DWITH_TELEPATHY=OFF \
	-DWITH_GCRYPT=OFF \
	-DWITH_LIBSSH=OFF \
	-DWITH_WAYLAND=OFF \
	-DWITH_VTE=OFF \
	-DWITH_LIBSECRET=OFF

ifeq ($(call qstrip,$(BR2_ARCH)),x86_64)
REMMINA_CONF_OPTS += -DWITH_SSE2=ON
else ifeq ($(call qstrip,$(BR2_ARCH)),i686)
REMMINA_CONF_OPTS += -DWITH_SSE2=ON
endif

REMMINA_DEPENDENCIES = \
	libgtk3 libvncserver freerdp \
	xlib_libX11 xlib_libXext xlib_libxkbfile

ifeq ($(BR2_NEEDS_GETTEXT),y)
REMMINA_DEPENDENCIES += gettext

define REMMINA_POST_PATCH_FIXINTL
	$(SED) 's/$${GTK_LIBRARIES}/$${GTK_LIBRARIES} -lintl/' \
		$(@D)/remmina/CMakeLists.txt
endef

REMMINA_POST_PATCH_HOOKS += REMMINA_POST_PATCH_FIXINTL
endif

$(eval $(cmake-package))
