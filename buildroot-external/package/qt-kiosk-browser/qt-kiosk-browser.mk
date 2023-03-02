################################################################################
#
# qt-kiosk-browser
#
################################################################################

QT_KIOSK_BROWSER_VERSION = 9ebcb0956179d5f671abc5f713aef81da12d852a
QT_KIOSK_BROWSER_SITE = https://github.com/OSSystems/qt-kiosk-browser.git
QT_KIOSK_BROWSER_SITE_METHOD = git
QT_KIOSK_BROWSER_DEPENDENCIES = qt5webengine
QT_KIOSK_BROWSER_LICENSE = LGPL-3.0
QT_KIOSK_BROWSER_LICENSE_FILES = doc/lgpl.html

define QT_KIOSK_BROWSER_CONFIGURE_CMDS
	(cd $(@D); $(TARGET_MAKE_ENV) $(QT5_QMAKE) PREFIX=/usr)
endef

define QT_KIOSK_BROWSER_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)
endef

define QT_KIOSK_BROWSER_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) -f Makefile \
		INSTALL_ROOT=$(TARGET_DIR) \
		install_target
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		INSTALL_ROOT=$(TARGET_DIR)
endef

$(eval $(generic-package))
