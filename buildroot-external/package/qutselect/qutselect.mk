################################################################################
#
# qutselect
#
################################################################################

QUTSELECT_VERSION = 2.1
QUTSELECT_TAG = master
QUTSELECT_SITE = $(call github,hzdr,qutselect,$(QUTSELECT_TAG))
QUTSELECT_LICENSE = LGPL-3.0
QUTSELECT_LICENSE_FILES = LICENSE
QUTSELECT_DEPENDENCIES = qt5base
QUTSELECT_INSTALL_TARGET = YES

define QUTSELECT_BUILD_CMDS
  $(MAKE) CMAKE_OPTIONS="-DCMAKE_INSTALL_PREFIX:PATH=/" CC="$(TARGET_CC)" LD="$(TARGET_LD)" CFLAGS="$(TARGET_CFLAGS)" -C $(@D) all
endef

define QUTSELECT_INSTALL_TARGET_CMDS
  $(INSTALL) -D -m 0755 $(@D)/build-l64/bin/qutselect-$(QUTSELECT_VERSION) $(TARGET_DIR)/bin/qutselect
  $(INSTALL) -D -m 0644 $(@D)/qutselect.slist $(TARGET_DIR)/bin/
  $(INSTALL) -D -m 0644 $(@D)/qutselect.motd $(TARGET_DIR)/bin/
  cp -R $(@D)/scripts $(TARGET_DIR)/bin/
endef

$(eval $(generic-package))
