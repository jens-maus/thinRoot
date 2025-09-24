#!/bin/sh
#
# Script to query and display the current keyboard layout
# on the display via a OSD call
#

if [ -x /usr/bin/osd_cat ]; then
  export LANG=en_US.UTF-8
  export DISPLAY=:0
  KBLAYOUT=$(/usr/bin/xkb-switch -p | awk -F'[(]' '{print toupper($1)}')
  if [ -n "${KBLAYOUT}" ]; then
    # kill previous osd_cat
    pkill /usr/bin/osd_cat
    COLOR=orange
    echo "Keyboard layout: ${KBLAYOUT}" | /usr/bin/osd_cat -A center -p top -f '-*-fixed-bold-r-*-*-30-*-*-*-*-*-*-*' -c "${COLOR}" -s 5 -d 3 &
  fi
fi
