#!/bin/sh
# shellcheck shell=dash
#
# shell script that starts qutselect after having setup all necessary
# configuration files

get_qutselect_files()
{
  # make sure we have a qutselect config dir in the user home
  if [ ! -d "${HOME}/.qutselect" ] ; then
    mkdir -p "${HOME}/.qutselect"
  fi

  # get the .slist file
  if [ -n "${SESSION_0_QUTSELECT_SLIST}" ]; then
    /usr/bin/wget -q "${BASE_PATH}/conf/${SESSION_0_QUTSELECT_SLIST}" -O "${HOME}/.qutselect/qutselect.slist"
  fi

  # get the .motd file
  if [ -n "${SESSION_0_QUTSELECT_MOTD}" ]; then
    /usr/bin/wget -q "${BASE_PATH}/conf/${SESSION_0_QUTSELECT_MOTD}" -O "${HOME}/.qutselect/qutselect.motd"
  fi

  return 0
}

# get the slist and motd files
get_qutselect_files

if [ -z "${SESSION_0_QUTSELECT_CMD}" ]; then
  SESSION_0_QUTSELECT_CMD="/bin/qutselect -dtlogin -nouser -keep"
fi

# start qutselect
${SESSION_0_QUTSELECT_CMD}
