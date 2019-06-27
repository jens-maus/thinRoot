#!/bin/sh
for MNTPATH in $(grep /media/usb /proc/mounts | awk '{ print $2 }'); do
  /bin/umount ${MNTPATH}
done
for BINDPATH in $(grep /usbmount /proc/mounts | awk '{ print $2 }'); do
  /bin/umount ${BINDPATH}
  /bin/rmdir ${BINDPATH}
done
