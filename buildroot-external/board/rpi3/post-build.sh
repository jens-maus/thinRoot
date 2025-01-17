#!/bin/sh

# Stop on error
set -e

# create VERSION file
echo "VERSION=${PRODUCT_VERSION}" >"${TARGET_DIR}/VERSION"
echo "PRODUCT=${PRODUCT}" >>"${TARGET_DIR}/VERSION"
echo "PLATFORM=rpi3" >>"${TARGET_DIR}/VERSION"

# link VERSION in /boot on rootfs
mkdir -p "${TARGET_DIR}/boot"
ln -sf ../VERSION "${TARGET_DIR}/boot/VERSION"

# remove /etc/dbus-1/system.d/pulseaudio-system.conf
rm -f "${TARGET_DIR}/etc/dbus-1/system.d/pulseaudio-system.conf"

# remove /etc/init.d/S40xorg as not needed
rm -f "${TARGET_DIR}/etc/init.d/S40xorg"

# remove /etc/X11/xorg.conf.d/20-intel.conf as it will not work on rpi
rm -f "${TARGET_DIR}/etc/X11/xorg.conf.d/20-intel.conf"
