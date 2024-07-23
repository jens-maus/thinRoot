################################################################################
#
# yoe-kiosk-browser
#
################################################################################

YOE_KIOSK_BROWSER_VERSION = 610be9b29fb348576264ff2e44a584c152f3f390
YOE_KIOSK_BROWSER_SITE = https://github.com/YoeDistro/yoe-kiosk-browser
YOE_KIOSK_BROWSER_SITE_METHOD = git
YOE_KIOSK_BROWSER_DEPENDENCIES = qt6base
YOE_KIOSK_BROWSER_LICENSE = LGPL-3.0

#define QT_WEBENGINE_KIOSK_CONFIGURE_CMDS
#	(cd $(@D); $(TARGET_MAKE_ENV) $(QT5_QMAKE) PREFIX=/usr)
#endef
#
#define QT_WEBENGINE_KIOSK_BUILD_CMDS
#	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)
#endef
#
#define QT_WEBENGINE_KIOSK_INSTALL_TARGET_CMDS
#	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/src -f Makefile.qt-webengine-kiosk \
#		INSTALL_ROOT=$(TARGET_DIR) \
#		install_target
#	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
#		INSTALL_ROOT=$(TARGET_DIR)
#endef

$(eval $(cmake-package))
