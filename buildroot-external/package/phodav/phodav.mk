################################################################################
#
# phodav
#
# https://gitlab.gnome.org/GNOME/phodav
#
################################################################################

PHODAV_VERSION = v3.0
PHODAV_SITE = https://github.com/GNOME/phodav.git
PHODAV_SITE_METHOD = git
PHODAV_LICENSE = LGPL-2.1
PHODAV_LICENSE_FILES = COPYING
PHODAV_INSTALL_STAGING = YES

PHODAV_DEPENDENCIES = libsoup3

define PHODAV_TARBALL_VERSION
	echo $(PHODAV_VERSION) | tr -d v >$(@D)/.tarball-version
endef
PHODAV_POST_PATCH_HOOKS += PHODAV_TARBALL_VERSION

$(eval $(meson-package))
