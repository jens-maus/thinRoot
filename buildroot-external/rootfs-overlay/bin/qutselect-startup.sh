#!/bin/sh

has_ewmh_wm()
{
  local name
  local id
  local child_id

  # If property does not exist, "id" will contain "no such atom on any window"
  id=`/usr/bin/xprop -root 32x ' $0\n' _NET_SUPPORTING_WM_CHECK | awk '{ print $2 }'`
  child_id=`/usr/bin/xprop -id "${id}" 32x ' $0\n' _NET_SUPPORTING_WM_CHECK 2>/dev/null | awk '{ print $2 }'`

  if [ "${id}" != "${child_id}" ]; then
    return 1
  fi

  return 0
}

wait_for_wm()
{
  for i in `seq 30`; do
    if has_ewmh_wm; then
      return 0
    fi

    sleep 1
  done
  return 1
}

get_qutselect_files()
{
  # make sure we have a qutselect config dir in the user home
  if [ ! -d $HOME/.qutselect ] ; then
    mkdir -p $HOME/.qutselect
  fi

  # get the .slist file
  if [ -n "${SESSION_0_QUTSELECT_SLIST}" ]; then
    /usr/bin/wget -q ${BASE_PATH}/conf/${SESSION_0_QUTSELECT_SLIST} -O ${HOME}/.qutselect/qutselect.slist
  fi

  # get the .motd file
  if [ -n "${SESSION_0_QUTSELECT_MOTD}" ]; then
    /usr/bin/wget -q ${BASE_PATH}/conf/${SESSION_0_QUTSELECT_MOTD} -O ${HOME}/.qutselect/qutselect.motd
  fi

  return 0
}

create_thinlinc_conf()
{
  # make sure we have a thinlinc config dir in the user home
  if [ ! -d $HOME/.thinlinc ] ; then
    mkdir -p $HOME/.thinlinc
  fi

  # link known_hosts file if not present
  if [ ! -e ${HOME}/.thinlinc/known_hosts ]; then
    ln -s /etc/ssh_known_hosts ${HOME}/.thinlinc/known_hosts
  fi

  # lets parse for SESSION_0_* env variables which we can forward
  # to the thinlinc configuration file
  TLCLIENTCONF=$HOME/.thinlinc/tlclient.conf
  set | grep _THINLINC_CONFIG_ | sed 's/SESSION_._THINLINC_CONFIG_//g' >>${TLCLIENTCONF}

  return 0
}

# get the slist and motd files
get_qutselect_files

# create thinlinc conf file
create_thinlinc_conf

# Clean up after earlier WMs
/usr/bin/xprop -root -remove _NET_NUMBER_OF_DESKTOPS \
                     -remove _NET_DESKTOP_NAMES \
                     -remove _NET_CURRENT_DESKTOP 2> /dev/null

# start wm
/usr/bin/fluxbox -no-slit -no-toolbar &

# wait for wm to start
if ! wait_for_wm; then
  echo "$0: Timeout waiting for wm to start"
fi

# update the default pa sink
/bin/pa-update-default-sink.sh

if [ -z "${SESSION_0_QUTSELECT_CMD}" ]; then
  SESSION_0_QUTSELECT_CMD="/bin/qutselect -dtlogin -nouser -keep"
fi

# start qutselect unlimited
while true; do
  ${SESSION_0_QUTSELECT_CMD} >/var/log/qutselect.log 2>&1
  if [ $? -ne 0 ]; then
    break 
  fi
done
