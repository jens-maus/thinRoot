#!/bin/sh

# Stop on error
set -e

# create VERSION file
echo "VERSION=${PRODUCT_VERSION}" >"${TARGET_DIR}/VERSION"
echo "PRODUCT=${PRODUCT}" >>"${TARGET_DIR}/VERSION"
echo "PLATFORM=tinkerboard" >>"${TARGET_DIR}/VERSION"

# link VERSION in /boot on rootfs
mkdir -p "${TARGET_DIR}/boot"
ln -sf ../VERSION "${TARGET_DIR}/boot/VERSION"

# remove /etc/dbus-1/system.d/pulseaudio-system.conf
rm -f "${TARGET_DIR}/etc/dbus-1/system.d/pulseaudio-system.conf"
rm -f "${TARGET_DIR}/usr/share/dbus-1/system.d/pulseaudio-system.conf"

# remove /etc/init.d/S40xorg as not needed
rm -f "${TARGET_DIR}/etc/init.d/S40xorg"

# remove /etc/X11/xorg.conf.d/20-intel.conf as it will not work on rpi
rm -f "${TARGET_DIR}/etc/X11/xorg.conf.d/20-intel.conf"

# remove /lib/dhcpcd/dhcpcd-hooks/50-timesyncd.conf as it is systemd only
rm -f "${TARGET_DIR}/lib/dhcpcd/dhcpcd-hooks/50-timesyncd.conf"

# remove unnecessary /etc/init.d/fuse3
rm -f "${TARGET_DIR}/etc/init.d/fuse3"

# remove unnecessary /usr/share/clc
rm -rf "${TARGET_DIR}/usr/share/clc"
