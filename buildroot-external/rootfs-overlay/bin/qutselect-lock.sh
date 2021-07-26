#!/bin/sh
# shellcheck shell=dash
#
# Small script which uses 'xdotool' to send keyboard shortcuts to the root window
# and thus will try to lock a session correctly.
#

# check if tlclient.bin is running, if yes send Ctrl+Alt+L to lock
# the screen
if /usr/bin/pgrep "tlclient.bin" >/dev/null 2>&1; then
  /bin/su - truser -c "DISPLAY=:0.0 /usr/bin/xdotool keydown Control_L keydown Alt_L key l keyup Alt_L keyup Control_L" &
else
  # otherwise we check for xfreerdp or rdesktop and then use Windows+L to lock
  # the windows session
  if /usr/bin/pgrep "xfreerdp|rdesktop|vncviewer" >/dev/null 2>&1; then
    /bin/su - truser -c "DISPLAY=:0.0 /usr/bin/xdotool keydown Super_L key l keyup Super_L" &
  else
    # bring the system into standby mode
    echo "standby" >/sys/power/state
  fi
fi
