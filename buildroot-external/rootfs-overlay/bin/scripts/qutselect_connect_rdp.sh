#!/bin/sh
# shellcheck shell=dash disable=SC2169
#
# This is a startup script for qutselect which initates a
# RDP session to a windows server either via rdesktop or uttsc
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
#

XFREERDP=/usr/bin/xfreerdp
TLSSOPASSWORD=/opt/thinlinc/bin/tl-sso-password
TLBESTWINSERVER=/opt/thinlinc/bin/tl-best-winserver

#####################################################
# check that we have 10 command-line options at hand
if [ $# -lt 10 ]; then
   echo "ERROR: missing arguments!"
   exit 2
fi

# catch all arguments is some local variables
#parentPID="${1}"
#serverType="${2}"
dtlogin="${3}"
resolution="${4}"
#colorDepth="${5}"
#curDepth="${6}"
keyLayout="${7}"
domain="${8}"
username="${9}"
serverName="${10}"

# if this is a ThinLinc session we can grab the password
# using the tl-sso-password command in case the user wants
# to connect to one of our servers (FZR domain)
if [ -x ${TLSSOPASSWORD} ]; then
  if ${TLSSOPASSWORD} -c && [ "${domain}" = "FZR" ]; then
    password=$(${TLSSOPASSWORD})
  fi
fi

# read the password from stdin if not specified yet
if [ -z "${password}" ]; then
  read -r password
fi

# if the serverName contains more than one server we go and
# check via the check_nrpe command which server to prefer
serverList=$(echo "${serverName}" | tr -s ',' ' ')
numServers=$(echo "${serverList}" | wc -w)
if [ "${numServers}" -gt 1 ]; then
  # check if we can find a suitable binary
  if [ -x ${TLBESTWINSERVER} ]; then
    bestServer=$(${TLBESTWINSERVER} "${serverList}")
    res=$?
  else
    # as an alternative we search for the tool in the scripts subdir
    # this tool also allows to override the username via -u
    if [ -x "scripts/tl-best-winserver" ]; then 
      bestServer=$(scripts/tl-best-winserver -u "${username}" "${serverList}")
      res=$?
    else
      # we don't have tl-best-winserver so lets simply take the first
      # one in the list
      bestServer=$(echo "${serverList}" | awk '{ print $1 }')
      res=0
    fi
  fi
  if [ $res -eq 0 ]; then
    serverName=${bestServer}
  fi
fi

# variable to prepare the command arguments
cmdArgs=""
RET=2

## XFREERDP
# if $cmdArgs is empty and xfreerdp exists use that one
if [ -z "${cmdArgs}" ] && [ -x ${XFREERDP} ]; then

  # resolution
  if [ "${resolution}" = "fullscreen" ]; then
     cmdArgs="$cmdArgs /f"

     # enable multi monitor support, but only if the two displays
     # are not mirrored (offset = 0)
     for r in $(xrandr | grep " connected" | cut -d " " -f3); do
       x=$(echo "${r}" | cut -d "+" -f2)

       # check the x-offset for being non-zero and if so
       # enable multimon support
       if [ "${x}" -ne 0 ]; then
         cmdArgs="$cmdArgs /multimon"
         break
       fi
     done

  else
     cmdArgs="$cmdArgs /size:${resolution}"
  fi

  # color depth
  #cmdArgs="$cmdArgs /bpp:${colorDepth}"
  cmdArgs="$cmdArgs /bpp:32"

  # keyboard
  if [ "${keyLayout}" = "de" ]; then
     cmdArgs="$cmdArgs /kbd:0x407" # German
  else
     cmdArgs="$cmdArgs /kbd:0x409" # US
  fi

  # add domain
  if [ "x${domain}" != "xNULL" ]; then
    cmdArgs="$cmdArgs /d:${domain}"
  else
    cmdArgs="$cmdArgs /d:FZR"
  fi

  # add username
  if [ "x${username}" != "xNULL" ]; then
    cmdArgs="$cmdArgs /u:${username}"
  else
    if [ "x${domain}" != "xNULL" ]; then
      cmdArgs="$cmdArgs /u:${domain}\\"
    fi
  fi

  # set the window title to the server name we connect to
  cmdArgs="$cmdArgs /t:${username}@${serverName}"

  # ignore the certificate in case of encryption
  cmdArgs="$cmdArgs /cert-ignore"

  # add the usb path as a local path. if TLSESSIONDATA is set
  # we are in a thinlinc session and thus have to forward
  # ${HOME}/thindrives/mnt instead
  if [ -n "${TLSESSIONDATA}" ]; then
    mkdir -p "${TLSESSIONDATA}/drives"
    cmdArgs="$cmdArgs /drive:USB,${TLSESSIONDATA}/drives/"
  else
     if [ -n "${SUN_SUNRAY_TOKEN}" ]; then
       cmdArgs="$cmdArgs /drive:USB,/tmp/SUNWut/mnt/${USER}/"
     else
       cmdArgs="$cmdArgs /drive:USB,/run/usbmount/"
     fi
  fi

  # enable sound redirection
  cmdArgs="$cmdArgs /sound:sys:pulse"

  # enable audio input redirection
  cmdArgs="$cmdArgs /microphone:sys:pulse"

  # performance optimization options
  cmdArgs="$cmdArgs +auto-reconnect +fonts +window-drag -menu-anims -themes +wallpaper +heartbeat /dynamic-resolution /gdi:hw /rfx /gfx:avc444 +gfx-thin-client /video /network:lan"
  
  # if we are not in dtlogin mode we go and
  # output the rdesktop line that is to be executed
  if [ "x${dtlogin}" != "xtrue" ]; then

    # add clipboard synchronization (only required in non-dtlogin mode)
    cmdArgs="$cmdArgs /clipboard"

    echo "${XFREERDP} ${cmdArgs} /v:${serverName}"
  else
    # disable the full-screen toggling and floatbar in case we are in dtlogin mode
    cmdArgs="$cmdArgs -toggle-fullscreen"
  fi

  # increase logging
  cmdArgs="$cmdArgs /log-level:INFO"

  # run xfreerdp finally
  if [ "x${password}" != "xNULL" ]; then
    cmdArgs="$cmdArgs /from-stdin"
    # shellcheck disable=SC2086
    echo "${password}" | ${XFREERDP} ${cmdArgs} /v:"${serverName}" >/var/log/xfreerdp-$$.log 2>&1 &
    RET=$?
  else
    # shellcheck disable=SC2086
    ${XFREERDP} ${cmdArgs} /v:"${serverName}" >var/log/xfreerdp-$$.log 2>&1 &
    RET=$?
  fi

  if [ ${RET} -ne 0 ]; then
     cmdArgs=""
     echo "ERROR: couldn't start xfreerdp"
  fi
fi

exit ${RET}
