################################################################################
#
# xkb-switch
#
################################################################################

XKB_SWITCH_VERSION = 1.8.5
XKB_SWITCH_SITE = $(call github,sergei-mironov,xkb-switch,$(XKB_SWITCH_VERSION))
XKB_SWITCH_LICENSE = MIT
XKB_SWITCH_LICENSE_FILES = COPYING

XKB_SWITCH_DEPENDENCIES = xlib_libX11 xlib_libxkbfile
XKB_SWITCH_CONF_OPTS = \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DCMAKE_INSTALL_BINDIR=bin \
	-DCMAKE_INSTALL_LIBDIR=lib \
	-DCMAKE_INSTALL_MANDIR=share/man

$(eval $(cmake-package))
