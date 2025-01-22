################################################################################
#
# qt5webkit
#
################################################################################

QT5WEBKIT_VERSION = 5.212.0-alpha4
QT5WEBKIT_SITE = https://github.com/qtwebkit/qtwebkit/releases/download/qtwebkit-$(QT5WEBKIT_VERSION)
QT5WEBKIT_SOURCE = qtwebkit-$(QT5WEBKIT_VERSION).tar.xz
QT5WEBKIT_DEPENDENCIES = \
	host-bison host-flex host-gperf host-python3 host-ruby gstreamer1 \
	gst1-plugins-base icu leveldb jpeg libpng libxml2 libxslt qt5location \
	openssl qt5sensors qt5webchannel sqlite webp woff2
QT5WEBKIT_INSTALL_STAGING = YES

QT5WEBKIT_LICENSE_FILES = Source/WebCore/LICENSE-LGPL-2 Source/WebCore/LICENSE-LGPL-2.1

QT5WEBKIT_LICENSE = LGPL-2.1+, BSD-3-Clause, BSD-2-Clause
# Source files contain references to LGPL_EXCEPTION.txt but it is not included
# in the archive.
QT5WEBKIT_LICENSE_FILES += LICENSE.LGPLv21

ifeq ($(BR2_MIPS_CPU_MIPS32R6),y)
QT5WEBKIT_CONF_OPTS += -DENABLE_JIT=OFF
endif

ifeq ($(BR2_PACKAGE_QT5BASE_OPENGL),y)
QT5WEBKIT_CONF_OPTS += \
	-DENABLE_OPENGL=ON \
	-DQt5Gui_OPENGL_LIBRARIES="GL" \
	-DQt5Gui_EGL_LIBRARIES="EGL" \
	-DENABLE_WEBKIT2=ON
else
QT5WEBKIT_CONF_OPTS += \
	-DENABLE_OPENGL=OFF \
	-DENABLE_WEBKIT2=OFF
endif

ifeq ($(BR2_PACKAGE_QT5BASE_XCB),y)
QT5WEBKIT_DEPENDENCIES += xlib_libXcomposite xlib_libXext xlib_libXrender
endif

ifeq ($(BR2_PACKAGE_QT5DECLARATIVE),y)
QT5WEBKIT_DEPENDENCIES += qt5declarative
endif

ifeq ($(BR2_PACKAGE_LIBEXECINFO),y)
QT5WEBKIT_DEPENDENCIES += libexecinfo
endif

ifeq ($(BR2_TOOLCHAIN_USES_MUSL),y)
QT5WEBKIT_CONF_OPTS += -DENABLE_SAMPLING_PROFILER=OFF
endif

QT5WEBKIT_CONF_OPTS += \
	-DENABLE_TOOLS=OFF \
	-DPORT=Qt \
	-DPYTHON_EXECUTABLE=$(HOST_DIR)/bin/python3 \
	-DSHARED_CORE=ON \
	-DUSE_LIBHYPHEN=OFF

define QT5WEBKIT_INSTALL_STAGING_FIX_INCLUDES
	rm -rf $(STAGING_DIR)/usr/include/qt5/QtWebKit
	mv -v $(STAGING_DIR)/usr/include/QtWebKit $(STAGING_DIR)/usr/include/qt5/QtWebKit
	rm -rf $(STAGING_DIR)/usr/include/qt5/QtWebKitWidgets
	mv -v $(STAGING_DIR)/usr/include/QtWebKitWidgets $(STAGING_DIR)/usr/include/qt5/QtWebKitWidgets
endef
QT5WEBKIT_POST_INSTALL_STAGING_HOOKS += QT5WEBKIT_INSTALL_STAGING_FIX_INCLUDES
define QT5WEBKIT_INSTALL_STAGING_FIX_MKSPECS
	sed -i 's/\/usr\/include/$$$$QT_MODULE_INCLUDE_BASE/g' $(STAGING_DIR)/usr/mkspecs/modules/qt_lib*.pri
	sed -i 's/\/usr\/lib/$$$$QT_MODULE_LIB_BASE/g' $(STAGING_DIR)/usr/mkspecs/modules/qt_lib*.pri
	sed -i 's/\/usr\/bin/$$$$QT_MODULE_BIN_BASE/g' $(STAGING_DIR)/usr/mkspecs/modules/qt_lib*.pri
	mv -v $(STAGING_DIR)/usr/mkspecs/modules/qt_lib*.pri $(HOST_DIR)/usr/mkspecs/modules/
endef
QT5WEBKIT_POST_INSTALL_STAGING_HOOKS += QT5WEBKIT_INSTALL_STAGING_FIX_MKSPECS

define QT5WEBKIT_INSTALL_TARGET_CMDS
	cp -av $(@D)/lib/* $(TARGET_DIR)/usr/lib/
	cp -av $(@D)/imports/* $(TARGET_DIR)/usr/qml/
endef

$(eval $(cmake-package))
