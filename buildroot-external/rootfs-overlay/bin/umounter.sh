#!/bin/sh

# show an OSD display
if [ -x /usr/bin/osd_cat ]; then
  export LANG=en_US.UTF-8
  export DISPLAY=:0
  echo "Unmounting USB..." | /usr/bin/osd_cat -A center -p top -f '-*-fixed-bold-r-*-*-30-*-*-*-*-*-*-*' -c green -s 5 -d 20 &
fi

# umount all stuff including bind mounts
grep "/media/usb" /proc/mounts | awk '{ print $2 }' | while read -r MNTPATH; do
  /bin/umount "${MNTPATH}"
done
grep "/usbmount" /proc/mounts | awk '{ print $2 }' | while read -r BINDPATH; do
  /bin/umount "${BINDPATH}"
  /bin/rmdir "${BINDPATH}"
done

# check if umount worked fine
if [ -x /usr/bin/osd_cat ]; then
  if ! grep -q -m1 "/media/usb" /proc/mounts 2>/dev/null &&
     ! grep -q -m1 "/usbmount" /proc/mounts 2>/dev/null; then
    RESULT="OK"
    POS=180
    COLOR=green
  else
    RESULT="FAIL"
    POS=200
    COLOR=red
  fi
  export LANG=en_US.UTF-8
  export DISPLAY=:0
  echo "${RESULT}" | /usr/bin/osd_cat -A center -p top -i ${POS} -f '-*-fixed-bold-r-*-*-30-*-*-*-*-*-*-*' -c ${COLOR} -s 5 -d 2
  pkill osd_cat
fi
