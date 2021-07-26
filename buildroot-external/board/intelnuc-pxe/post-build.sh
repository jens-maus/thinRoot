#!/bin/sh

# remove /etc/dbus-1/system.d/pulseaudio-system.conf
rm -f "${TARGET_DIR}/etc/dbus-1/system.d/pulseaudio-system.conf"

# remove /etc/init.d/S40xorg as not needed
rm -f "${TARGET_DIR}/etc/init.d/S40xorg"
