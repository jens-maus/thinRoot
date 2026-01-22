#!/bin/sh
# shellcheck shell=dash
#
# Generic shell script that make sure to start a basic windows manager after
# X11 has been started.

has_ewmh_wm()
{
  local id
  local child_id

  # If property does not exist, "id" will contain "no such atom on any window"
  id=$(/usr/bin/xprop -root 32x ' $0\n' _NET_SUPPORTING_WM_CHECK | awk '{ print $2 }')
  child_id=$(/usr/bin/xprop -id "${id}" 32x ' $0\n' _NET_SUPPORTING_WM_CHECK 2>/dev/null | awk '{ print $2 }')

  if [ "${id}" != "${child_id}" ]; then
    return 1
  fi

  return 0
}

wait_for_wm()
{
  # shellcheck disable=SC2034
  for i in $(seq 30); do
    if has_ewmh_wm; then
      return 0
    fi

    sleep 1
  done
  return 1
}

create_thinlinc_conf()
{
  # make sure we have a thinlinc config dir in the user home
  if [ ! -d "${HOME}/.thinlinc" ] ; then
    mkdir -p "${HOME}/.thinlinc"
  fi

  # link known_hosts file if not present
  if [ ! -e "${HOME}/.thinlinc/known_hosts" ]; then
    ln -s /etc/ssh_known_hosts "${HOME}/.thinlinc/known_hosts"
  fi

  # lets parse for SESSION_0_* env variables which we can forward
  # to the thinlinc configuration file
  TLCLIENTCONF=${HOME}/.thinlinc/tlclient.conf
  set | grep _THINLINC_CONFIG_ | sed 's/SESSION_._THINLINC_CONFIG_//g' | tr -d \' >"${TLCLIENTCONF}"

  return 0
}

# create thinlinc conf file
create_thinlinc_conf

# Clean up after earlier WMs
/usr/bin/xprop -root -remove _NET_NUMBER_OF_DESKTOPS \
                     -remove _NET_DESKTOP_NAMES \
                     -remove _NET_CURRENT_DESKTOP 2> /dev/null

# start compositor process (xcompmgr)
/usr/bin/xcompmgr &
sleep 0.2

# start wm (openbox is the default)
if [ -z "${SESSION_0_WM}" ]; then
  SESSION_0_WM=/usr/bin/openbox
fi
${SESSION_0_WM} &

# wait for wm to start
if ! wait_for_wm; then
  echo "$0: Timeout waiting for wm to start"
fi

# set solid background color in root window
/usr/bin/xsetroot -solid "#32436B"

# move mouse pointer off screen to hide it in case
# a user wants this upon startup
if [ "${SESSION_0_HIDECURSOR}" = "true" ]; then
  /usr/bin/xdotool mousemove 0 5000
fi

# update the default pulseaudio sink
#/bin/pa-update-default-sink.sh

# if SESSION_0_STARTUP is not set we start qutselect-startup.sh as the
# default topmost application
if [ -z "${SESSION_0_XSTARTUP}" ]; then
  SESSION_0_XSTARTUP="/bin/qutselect-startup.sh"
fi

# start qutselect unlimited
while true; do
  if ! ${SESSION_0_XSTARTUP}; then
    break 
  fi
done
