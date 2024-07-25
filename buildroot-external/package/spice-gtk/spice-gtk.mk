################################################################################
#
# spice-gtk
#
# https://gitlab.freedesktop.org/spice/spice-gtk
#
################################################################################

SPICE_GTK_VERSION = 0.41
SPICE_GTK_SOURCE = spice-gtk-$(SPICE_GTK_VERSION).tar.xz
SPICE_GTK_SITE = https://www.spice-space.org/download/gtk
SPICE_GTK_LICENSE = GPL-2.0
SPICE_GTK_LICENSE_FILES = COPYING
SPICE_GTK_INSTALL_STAGING = YES

SPICE_GTK_DEPENDENCIES = spice-protocol host-python-six host-python-pyparsing jpeg json-glib gstreamer1 gst1-plugins-base usbredir usbutils phodav opus

SPICE_GTK_CONF_OPTS += -Dusb-ids-path=/usr/share/hwdata/usb.ids

$(eval $(meson-package))
