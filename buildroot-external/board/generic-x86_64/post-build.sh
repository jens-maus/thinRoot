#!/bin/sh

# create VERSION file
echo "VERSION=${PRODUCT_VERSION}" >"${TARGET_DIR}/VERSION"
echo "PRODUCT=${PRODUCT}" >>"${TARGET_DIR}/VERSION"
echo "PLATFORM=generic-x86_64" >>"${TARGET_DIR}/VERSION"

# remove /etc/dbus-1/system.d/pulseaudio-system.conf
rm -f "${TARGET_DIR}/etc/dbus-1/system.d/pulseaudio-system.conf"
rm -f "${TARGET_DIR}/usr/share/dbus-1/system.d/pulseaudio-system.conf"

# remove /etc/init.d/S40xorg as not needed
rm -f "${TARGET_DIR}/etc/init.d/S40xorg"

# remove /lib/dhcpcd/dhcpcd-hooks/50-timesyncd.conf as it is systemd only
rm -f "${TARGET_DIR}/lib/dhcpcd/dhcpcd-hooks/50-timesyncd.conf"

# remove unnecessary /etc/init.d/fuse3
rm -f "${TARGET_DIR}/etc/init.d/fuse3"
