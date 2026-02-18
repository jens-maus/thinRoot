################################################################################
#
# libxfce4ui
#
################################################################################

LIBXFCE4UI_VERSION = 4.20.2
LIBXFCE4UI_SOURCE = libxfce4ui-$(LIBXFCE4UI_VERSION).tar.bz2
LIBXFCE4UI_SITE = https://archive.xfce.org/src/xfce/libxfce4ui/4.20
LIBXFCE4UI_LICENSE = LGPL-2.1+
LIBXFCE4UI_LICENSE_FILES = COPYING

# Install to staging so that pkg-config/headers are available for dependent builds (xfwm4).
LIBXFCE4UI_INSTALL_STAGING = YES

# Upstream ships a ltmain.sh variant where Buildroot's generic libtool patch
# no longer applies cleanly (optional, keep if you already set it).
LIBXFCE4UI_LIBTOOL_PATCH = NO

LIBXFCE4UI_DEPENDENCIES = \
	host-pkgconf \
	host-gettext \
	libgtk3 \
	xfconf \
	libxfce4util

LIBXFCE4UI_CONF_OPTS = \
	--disable-debug \
	--disable-gtk-doc \
	--disable-maintainer-mode \
	--disable-vala

define LIBXFCE4UI_POST_INSTALL_TARGET_RM_LA
	rm -f $(TARGET_DIR)/usr/lib/*.la
endef
LIBXFCE4UI_POST_INSTALL_TARGET_HOOKS += LIBXFCE4UI_POST_INSTALL_TARGET_RM_LA

# ---------------------------------------------------------------------------
# Avoid libtool install-time relinking entirely.
#
# "make install" (both to staging and target) triggers a libtool relink of
# libxfce4kbd-private-3.la, and libtool injects an unsafe -L/usr/lib which
# Buildroot rightfully rejects.
#
# We only need:
#  - shared libs (.so*)
#  - headers (for builds using staging)
#  - pkg-config files
#  - (optional) keyboard shortcuts XML
# ---------------------------------------------------------------------------

define LIBXFCE4UI_INSTALL_STAGING_CMDS
	# shared libs
	$(INSTALL) -D -m 0755 $(@D)/libxfce4ui/.libs/libxfce4ui-2.so.* \
		$(STAGING_DIR)/usr/lib/
	# ensure unversioned symlink exists for linkers using -lxfce4ui-2
	ln -sf $$(basename $$(ls -1 $(STAGING_DIR)/usr/lib/libxfce4ui-2.so.* | tail -n 1)) \
		$(STAGING_DIR)/usr/lib/libxfce4ui-2.so
	# best-effort major symlink
	ln -sf $$(basename $$(ls -1 $(STAGING_DIR)/usr/lib/libxfce4ui-2.so.* | tail -n 1)) \
		$(STAGING_DIR)/usr/lib/libxfce4ui-2.so.0 || true

	$(if $(wildcard $(@D)/libxfce4kbd-private/.libs/libxfce4kbd-private-3.so.*), \
		$(INSTALL) -D -m 0755 $(@D)/libxfce4kbd-private/.libs/libxfce4kbd-private-3.so.* \
			$(STAGING_DIR)/usr/lib/;)
	# ensure unversioned symlink exists for linkers using -lxfce4kbd-private-3
	$(if $(wildcard $(STAGING_DIR)/usr/lib/libxfce4kbd-private-3.so.*), \
		ln -sf $$(basename $$(ls -1 $(STAGING_DIR)/usr/lib/libxfce4kbd-private-3.so.* | tail -n 1)) \
			$(STAGING_DIR)/usr/lib/libxfce4kbd-private-3.so;)
	# best-effort major symlink
	$(if $(wildcard $(STAGING_DIR)/usr/lib/libxfce4kbd-private-3.so.*), \
		ln -sf $$(basename $$(ls -1 $(STAGING_DIR)/usr/lib/libxfce4kbd-private-3.so.* | tail -n 1)) \
			$(STAGING_DIR)/usr/lib/libxfce4kbd-private-3.so.0 || true;)

	# pkg-config
	$(INSTALL) -D -m 0644 $(@D)/libxfce4ui/libxfce4ui-2.pc \
		$(STAGING_DIR)/usr/lib/pkgconfig/libxfce4ui-2.pc
	$(if $(wildcard $(@D)/libxfce4kbd-private/libxfce4kbd-private-3.pc), \
		$(INSTALL) -D -m 0644 $(@D)/libxfce4kbd-private/libxfce4kbd-private-3.pc \
			$(STAGING_DIR)/usr/lib/pkgconfig/libxfce4kbd-private-3.pc;)

	# public headers
	$(INSTALL) -D -m 0644 $(@D)/libxfce4ui/libxfce4ui.h \
		$(STAGING_DIR)/usr/include/xfce4/libxfce4ui-2/libxfce4ui/libxfce4ui.h
	$(INSTALL) -D -m 0644 $(@D)/libxfce4ui/libxfce4ui-config.h \
		$(STAGING_DIR)/usr/include/xfce4/libxfce4ui-2/libxfce4ui/libxfce4ui-config.h
	# install remaining headers from libxfce4ui (best-effort)
	$(INSTALL) -m 0644 $(@D)/libxfce4ui/*.h \
		$(STAGING_DIR)/usr/include/xfce4/libxfce4ui-2/libxfce4ui/ 2>/dev/null || true

	# private kbd headers (best-effort)
	$(if $(wildcard $(@D)/libxfce4kbd-private/*.h), \
		$(INSTALL) -D -m 0644 $(@D)/libxfce4kbd-private/*.h \
			$(STAGING_DIR)/usr/include/xfce4/libxfce4kbd-private-3/libxfce4kbd-private/ 2>/dev/null || true;)

	# optional XML (small, and used by xfce shortcut tooling)
	$(if $(wildcard $(@D)/libxfce4kbd-private/xfce4-keyboard-shortcuts.xml), \
		$(INSTALL) -D -m 0644 $(@D)/libxfce4kbd-private/xfce4-keyboard-shortcuts.xml \
			$(STAGING_DIR)/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml;)
endef

define LIBXFCE4UI_INSTALL_TARGET_CMDS
	# runtime shared libs only (no headers/pkgconfig)
	$(INSTALL) -D -m 0755 $(STAGING_DIR)/usr/lib/libxfce4ui-2.so.* \
		$(TARGET_DIR)/usr/lib/
	$(if $(wildcard $(STAGING_DIR)/usr/lib/libxfce4kbd-private-3.so.*), \
		$(INSTALL) -D -m 0755 $(STAGING_DIR)/usr/lib/libxfce4kbd-private-3.so.* \
			$(TARGET_DIR)/usr/lib/;)
	$(if $(wildcard $(STAGING_DIR)/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml), \
		$(INSTALL) -D -m 0644 \
			$(STAGING_DIR)/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml \
			$(TARGET_DIR)/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml;)
endef

$(eval $(autotools-package))
