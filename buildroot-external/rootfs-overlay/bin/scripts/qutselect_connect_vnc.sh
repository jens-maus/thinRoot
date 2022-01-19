#!/bin/sh
#
# This is a startup script for qutselect which initates a
# VNC session to a windows server via 'vncviewer'
#
# It receives the following inputs:
#
# $1 = PID of qutselect
# $2 = serverType (SRSS, RDP, VNC)
# $3 = 'true' if dtlogin mode was on while qutselect was running
# $4 = the resolution (either 'fullscreen' or 'WxH')
# $5 = the selected color depth (8, 16, 24)
# $6 = the current max. color depth (8, 16, 24)
# $7 = the selected keylayout (e.g. 'de' or 'en')
# $8 = the domain (e.g. 'FZR', used for RDP)
# $9 = the username
# $10 = the servername (hostname) to connect to

VNCVIEWER=/lib/tlclient/vncviewer

#####################################################
# check that we have 10 command-line options at hand
if [ $# -lt 10 ]; then
   printf "ERROR: missing arguments!"
   exit 2
fi

# catch all arguments is some local variables
#parentPID="${1}"
#serverType="${2}"
dtlogin="${3}"
resolution="${4}"
#colorDepth="${5}"
#curDepth="${6}"
#keyLayout="${7}"
#domain="${8}"
#username="${9}"
serverName="${10}"

# read the password from stdin
read -r password

# variable to prepare the command arguments
cmdArgs="-shared -menukey="

# resolution
if [ "${resolution}" = "fullscreen" ]; then
  cmdArgs="$cmdArgs -fullscreen -fullscreensystemkeys"
fi

# run vncviewer finally
if [ "${password}" != "NULL" ]; then
  if [ "${dtlogin}" != "true" ]; then
    echo "${VNCVIEWER} ${cmdArgs} ${serverName}"
  fi
  # shellcheck disable=SC2086
  VNC_PASSWORD="${password}" ${VNCVIEWER} ${cmdArgs} "${serverName}" 2>/dev/null >/dev/null
  RET=$?
else
  if [ "${dtlogin}" != "true" ]; then
    echo "${VNCVIEWER} ${cmdArgs} ${serverName}"
  fi
  # shellcheck disable=SC2086
  ${VNCVIEWER} ${cmdArgs} "${serverName}" 2>/dev/null >/dev/null
  RET=$?
fi

if [ $RET != 0 ]; then
   echo "ERROR: ${VNCVIEWER} returned invalid return code ($RET)"
   exit 2
fi

exit ${RET}
