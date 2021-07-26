#!/bin/sh
grep /media/usb /proc/mounts | awk '{ print $2 }' | while read -r MNTPATH; do
  /bin/umount "${MNTPATH}"
done
grep /usbmount /proc/mounts | awk '{ print $2 }' | while read -r BINDPATH; do
  /bin/umount "${BINDPATH}"
  /bin/rmdir "${BINDPATH}"
done
