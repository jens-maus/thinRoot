################################################################################
#
# freerdp3
#
################################################################################

FREERDP3_VERSION = 3.30.0
FREERDP3_SITE = $(call github,FreeRDP,FreeRDP,$(FREERDP3_VERSION))
FREERDP3_DEPENDENCIES = host-pkgconf libglib2 openssl zlib
FREERDP3_LICENSE = Apache-2.0
FREERDP3_LICENSE_FILES = LICENSE
FREERDP3_CPE_ID_VENDOR = freerdp
FREERDP3_INSTALL_STAGING = YES
FREERDP3_SUPPORTS_IN_SOURCE_BUILD = NO

FREERDP3_CONF_OPTS = \
	-DCMAKE_C_FLAGS="$(TARGET_CFLAGS) -Wno-incompatible-pointer-types" \
	-DWITH_MANPAGES=OFF -Wno-dev \
	-DPKG_CONFIG_EXECUTABLE=$(HOST_DIR)/bin/pkgconf \
	-DWITH_VERBOSE_WINPR_ASSERT=OFF

ifeq ($(BR2_PACKAGE_FREERDP3_GSTREAMER1),y)
FREERDP3_CONF_OPTS += -DWITH_GSTREAMER_1_0=ON
FREERDP3_DEPENDENCIES += gstreamer1 gst1-plugins-base
else
FREERDP3_CONF_OPTS += -DWITH_GSTREAMER_1_0=OFF
endif

ifeq ($(BR2_PACKAGE_CUPS),y)
FREERDP3_CONF_OPTS += -DWITH_CUPS=ON
FREERDP3_DEPENDENCIES += cups
else
FREERDP3_CONF_OPTS += -DWITH_CUPS=OFF
endif

ifeq ($(BR2_PACKAGE_FFMPEG),y)
FREERDP3_CONF_OPTS += -DWITH_FFMPEG=ON
FREERDP3_DEPENDENCIES += ffmpeg
else
FREERDP3_CONF_OPTS += -DWITH_FFMPEG=OFF
endif

ifeq ($(BR2_PACKAGE_ALSA_LIB_MIXER),y)
FREERDP3_CONF_OPTS += -DWITH_ALSA=ON
FREERDP3_DEPENDENCIES += alsa-lib
else
FREERDP3_CONF_OPTS += -DWITH_ALSA=OFF
endif

ifeq ($(BR2_PACKAGE_LIBEXECINFO),y)
FREERDP3_CONF_OPTS += -DCMAKE_EXE_LINKER_FLAGS=-lexecinfo
FREERDP3_DEPENDENCIES += libexecinfo
endif

ifeq ($(BR2_PACKAGE_LIBUSB),y)
FREERDP3_CONF_OPTS += -DCHANNEL_URBDRC=ON
FREERDP3_DEPENDENCIES += libusb
else
FREERDP3_CONF_OPTS += -DCHANNEL_URBDRC=OFF
endif

ifeq ($(BR2_PACKAGE_PULSEAUDIO),y)
FREERDP3_CONF_OPTS += -DWITH_PULSE=ON
FREERDP3_DEPENDENCIES += pulseaudio
else
FREERDP3_CONF_OPTS += -DWITH_PULSE=OFF
endif

# For the systemd journal
ifeq ($(BR2_PACKAGE_SYSTEMD),y)
FREERDP3_CONF_OPTS += -DWITH_SYSTEMD=ON
FREERDP3_DEPENDENCIES += systemd
else
FREERDP3_CONF_OPTS += -DWITH_SYSTEMD=OFF
endif

ifeq ($(BR2_PACKAGE_KRB5),y)
FREERDP3_CONF_OPTS += -DWITH_KRB5=ON
FREERDP3_DEPENDENCIES += krb5
else
FREERDP3_CONF_OPTS += -DWITH_KRB5=OFF
endif

ifeq ($(BR2_ARM_CPU_HAS_NEON),y)
FREERDP3_CONF_OPTS += -DWITH_NEON=ON
else
FREERDP3_CONF_OPTS += -DWITH_NEON=OFF
endif

ifeq ($(BR2_X86_CPU_HAS_SSE2),y)
FREERDP3_CONF_OPTS += -DWITH_SSE2=ON
else
FREERDP3_CONF_OPTS += -DWITH_SSE2=OFF
endif

#---------------------------------------
# Enabling server and/or client

# Clients and server interface must always be enabled to build the
# corresponding libraries.
FREERDP3_CONF_OPTS += -DWITH_SERVER_INTERFACE=ON
FREERDP3_CONF_OPTS += -DWITH_CLIENT_INTERFACE=ON

ifeq ($(BR2_PACKAGE_FREERDP3_SERVER),y)
FREERDP3_CONF_OPTS += -DWITH_SERVER=ON
endif

ifneq ($(BR2_PACKAGE_FREERDP3_CLIENT_X11)$(BR2_PACKAGE_FREERDP3_CLIENT_WL),)
FREERDP3_CONF_OPTS += -DWITH_CLIENT=ON
endif

#---------------------------------------
# Libraries for client and/or server

# The FreeRDP buildsystem uses non-orthogonal options. For example it
# is not possible to build the server and the wayland client without
# also building the X client. That's because the dependencies of the
# server (the X libraries) are a superset of those of the X client.
# So, as soon as FreeRDP is configured for the server and the wayland
# client, it will believe it also has to build the X client, because
# the libraries it needs are enabled.
#
# Furthermore, the shadow server is always built, even if there's nothing
# it can serve (i.e. the X libs are disabled).
#
# So, we do not care whether we build too much; we remove, as
# post-install hooks, whatever we do not want.

# If Xorg is enabled, and the server or the X client are, then libX11
# and libXext are forcibly enabled at the Kconfig level. However, if
# Xorg is enabled but neither the server nor the X client are, then
# there's nothing that guarantees those two libs are enabled. So we
# really must check for them.
ifeq ($(BR2_PACKAGE_XLIB_LIBX11)$(BR2_PACKAGE_XLIB_LIBXEXT),yy)
FREERDP3_DEPENDENCIES += xlib_libX11 xlib_libXext
FREERDP3_CONF_OPTS += -DWITH_X11=ON
else
FREERDP3_CONF_OPTS += -DWITH_X11=OFF
endif

# The following libs are either optional or mandatory only for either
# the server or the client. A mandatory library for either one is
# selected from Kconfig, so we can make it conditional here
ifeq ($(BR2_PACKAGE_XLIB_LIBXCURSOR),y)
FREERDP3_CONF_OPTS += -DWITH_XCURSOR=ON
FREERDP3_DEPENDENCIES += xlib_libXcursor
else
FREERDP3_CONF_OPTS += -DWITH_XCURSOR=OFF
endif

ifeq ($(BR2_PACKAGE_XLIB_LIBXDAMAGE),y)
FREERDP3_CONF_OPTS += -DWITH_XDAMAGE=ON
FREERDP3_DEPENDENCIES += xlib_libXdamage
else
FREERDP3_CONF_OPTS += -DWITH_XDAMAGE=OFF
endif

ifeq ($(BR2_PACKAGE_XLIB_LIBXFIXES),y)
FREERDP3_CONF_OPTS += -DWITH_XFIXES=ON
FREERDP3_DEPENDENCIES += xlib_libXfixes
else
FREERDP3_CONF_OPTS += -DWITH_XFIXES=OFF
endif

ifeq ($(BR2_PACKAGE_XLIB_LIBXI),y)
FREERDP3_CONF_OPTS += -DWITH_XI=ON
FREERDP3_DEPENDENCIES += xlib_libXi
else
FREERDP3_CONF_OPTS += -DWITH_XI=OFF
endif

ifeq ($(BR2_PACKAGE_XLIB_LIBXINERAMA),y)
FREERDP3_CONF_OPTS += -DWITH_XINERAMA=ON
FREERDP3_DEPENDENCIES += xlib_libXinerama
else
FREERDP3_CONF_OPTS += -DWITH_XINERAMA=OFF
endif

ifeq ($(BR2_PACKAGE_XLIB_LIBXKBFILE),y)
FREERDP3_CONF_OPTS += -DWITH_XKBFILE=ON
FREERDP3_DEPENDENCIES += xlib_libxkbfile
else
FREERDP3_CONF_OPTS += -DWITH_XKBFILE=OFF
endif

ifeq ($(BR2_PACKAGE_XLIB_LIBXRANDR),y)
FREERDP3_CONF_OPTS += -DWITH_XRANDR=ON
FREERDP3_DEPENDENCIES += xlib_libXrandr
else
FREERDP3_CONF_OPTS += -DWITH_XRANDR=OFF
endif

ifeq ($(BR2_PACKAGE_XLIB_LIBXRENDER),y)
FREERDP3_CONF_OPTS += -DWITH_XRENDER=ON
FREERDP3_DEPENDENCIES += xlib_libXrender
else
FREERDP3_CONF_OPTS += -DWITH_XRENDER=OFF
endif

ifeq ($(BR2_PACKAGE_XLIB_LIBXTST),y)
FREERDP3_CONF_OPTS += -DWITH_XTEST=ON
FREERDP3_DEPENDENCIES += xlib_libXtst
else
FREERDP3_CONF_OPTS += -DWITH_XTEST=OFF
endif

ifeq ($(BR2_PACKAGE_XLIB_LIBXV),y)
FREERDP3_CONF_OPTS += -DWITH_XV=ON
FREERDP3_DEPENDENCIES += xlib_libXv
else
FREERDP3_CONF_OPTS += -DWITH_XV=OFF
endif

ifeq ($(BR2_PACKAGE_FREERDP3_CLIENT_WL),y)
FREERDP3_DEPENDENCIES += wayland libxkbcommon
FREERDP3_CONF_OPTS += \
	-DWITH_WAYLAND=ON \
	-DWAYLAND_SCANNER=$(HOST_DIR)/bin/wayland-scanner
else
FREERDP3_CONF_OPTS += -DWITH_WAYLAND=OFF
endif

ifeq ($(BR2_PACKAGE_FREERDP3_RDPECAM),y)
FREERDP3_CONF_OPTS += \
	-DCHANNEL_RDPECAM=ON \
	-DCHANNEL_RDPECAM_CLIENT=ON
FREERDP3_DEPENDENCIES += libv4l
else
FREERDP3_CONF_OPTS += \
	-DCHANNEL_RDPECAM=OFF \
	-DCHANNEL_RDPECAM_CLIENT=OFF
endif

ifeq ($(BR2_PACKAGE_FREERDP3_FUSE),y)
FREERDP3_CONF_OPTS += -DWITH_FUSE=ON
FREERDP3_DEPENDENCIES += libfuse3
else
FREERDP3_CONF_OPTS += -DWITH_FUSE=OFF
endif

#---------------------------------------
# Post-install hooks to cleanup and install missing stuff

# Shadow server is always installed, no matter what, so we manually
# remove it if the user does not want the server.
ifeq ($(BR2_PACKAGE_FREERDP3_SERVER),)
define FREERDP3_RM_SHADOW_SERVER
	rm -f $(TARGET_DIR)/usr/bin/freerdp-shadow
endef
FREERDP3_POST_INSTALL_TARGET_HOOKS += FREERDP3_RM_SHADOW_SERVER
endif # ! server

# X client is always built as soon as a client is enabled and the
# necessary libs are enabled (e.g. because of the server), so manually
# remove it if the user does not want it.
ifeq ($(BR2_PACKAGE_FREERDP3_CLIENT_X11),)
define FREERDP3_RM_CLIENT_X11
	rm -f $(TARGET_DIR)/usr/bin/xfreerdp
	rm -f $(TARGET_DIR)/usr/lib/libxfreerdp-client*
endef
FREERDP3_POST_INSTALL_TARGET_HOOKS += FREERDP3_RM_CLIENT_X11
define FREERDP3_RM_CLIENT_X11_LIB
	rm -f $(STAGING_DIR)/usr/lib/libxfreerdp-client*
endef
FREERDP3_POST_INSTALL_STAGING_HOOKS += FREERDP3_RM_CLIENT_X11_LIB
endif # ! X client

# Wayland client is always built as soon as wayland is enabled, so
# manually remove it if the user does not want it.
ifeq ($(BR2_PACKAGE_FREERDP3_CLIENT_WL),)
define FREERDP3_RM_CLIENT_WL
	rm -f $(TARGET_DIR)/usr/bin/wlfreerdp
endef
FREERDP3_POST_INSTALL_TARGET_HOOKS += FREERDP3_RM_CLIENT_WL
endif

# Remove static libraries in unusual dir and development files not needed on target
define FREERDP3_CLEANUP
	rm -rf $(TARGET_DIR)/usr/lib/freerdp
	rm -rf $(TARGET_DIR)/usr/include/freerdp3
	rm -rf $(TARGET_DIR)/usr/include/winpr3
	rm -rf $(TARGET_DIR)/usr/lib/cmake/FreeRDP3
	rm -rf $(TARGET_DIR)/usr/lib/cmake/FreeRDP-Client3
	rm -rf $(TARGET_DIR)/usr/lib/cmake/FreeRDP-Server3
	rm -rf $(TARGET_DIR)/usr/lib/cmake/FreeRDP-Shadow3
	rm -rf $(TARGET_DIR)/usr/lib/cmake/FreeRDP-Proxy3
	rm -rf $(TARGET_DIR)/usr/lib/cmake/WinPR3
	rm -rf $(TARGET_DIR)/usr/lib/cmake/WinPR-tools3
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/freerdp3.pc
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/freerdp-client3.pc
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/freerdp-server3.pc
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/freerdp-shadow3.pc
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/freerdp-server-proxy3.pc
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/winpr3.pc
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/winpr-tools3.pc
endef
FREERDP3_POST_INSTALL_TARGET_HOOKS += FREERDP3_CLEANUP


$(eval $(cmake-package))
