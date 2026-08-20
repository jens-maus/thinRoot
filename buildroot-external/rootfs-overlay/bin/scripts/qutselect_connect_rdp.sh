#!/bin/bash
# shellcheck shell=dash disable=SC3010,SC3020,SC3014,SC3015
#
# This is a startup script for qutselect which initates a
# RDP session to a windows server
#
# It receives the following inputs:
#
# $1 = PID of qutselect
# $2 = serverType (RDP, VNC)
# $3 = 'true' if dtlogin mode was on while qutselect was running
# $4 = the resolution (either 'fullscreen' or 'WxH')
# $5 = the selected color depth (8, 16, 24)
# $6 = the current max. color depth (8, 16, 24)
# $7 = the selected keylayout (e.g. 'de' or 'en')
# $8 = the domain (e.g. 'FZR', used for RDP)
# $9 = the username
# $10 = the servername (hostname) to connect to
#

if [[ -x /usr/local/bin/xfreerdp ]]; then
  XFREERDP=/usr/local/bin/xfreerdp
elif [[ -x /usr/bin/xfreerdp ]]; then
  XFREERDP=/usr/bin/xfreerdp
else
  XFREERDP=xfreerdp
fi

TLSSOPASSWORD=/opt/thinlinc/bin/tl-sso-password
TLBESTWINSERVER=/opt/thinlinc/bin/tl-best-winserver
ZENITY=/bin/zenity

#####################################################
# check that we have 10 command-line options at hand
if [[ $# -lt 10 ]]; then
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

# make sure files are generated for user only
umask 077

# if this is a ThinLinc session we can grab the password
# using the tl-sso-password command in case the user wants
# to connect to one of our servers (FZR domain)
if [[ -x ${TLSSOPASSWORD} ]] &&
  ${TLSSOPASSWORD} -c 2>/dev/null; then
  if [[ "${domain}" = "FZR" ]]; then
    password=$(${TLSSOPASSWORD})
  fi
fi

# read the password from stdin if not specified yet
if [[ -z "${password}" ]]; then
  read -r password
fi

# if we still have not a password yet we query it from the user via
# zenity
if [[ -x ${ZENITY} ]] && [[ "${password}" == "NULL" ]]; then
  password=$(${ZENITY} --password --title="${username}@${serverName}" --timeout=20)
fi

# if the serverName contains more than one server we go and
# check via the check_nrpe command which server to prefer
serverList=$(echo "${serverName}" | tr -s ',' ' ')
numServers=$(echo "${serverList}" | wc -w)
if [[ "${numServers}" -gt 1 ]]; then
  # check if we can find a suitable binary
  if [[ -x ${TLBESTWINSERVER} ]]; then
    # shellcheck disable=SC2086
    bestServer=$(${TLBESTWINSERVER} ${serverList})
    res=$?
  else
    # as an alternative we search for the tool in the scripts subdir
    # this tool also allows to override the username via -u
    if [[ -x "scripts/tl-best-winserver" ]]; then
      # shellcheck disable=SC2086
      bestServer=$(scripts/tl-best-winserver -u "${username}" ${serverList})
      res=$?
    else
      # we don't have tl-best-winserver so lets simply take the first
      # one in the list
      bestServer=$(echo "${serverList}" | awk '{ print $1 }')
      res=0
    fi
  fi
  if [[ $res -eq 0 ]]; then
    serverName=${bestServer}
  fi
fi

# variable to prepare the command arguments
cmdArgs=""
res=2

## XFREERDP

# resolution
if [[ "${resolution}" == "fullscreen" ]]; then
   cmdArgs="$cmdArgs /f"

   # enable multi monitor support, but only if the two displays
   # are not mirrored (offset = 0)
   for r in $(xrandr | grep " connected" | cut -d " " -f3); do
     x=$(echo "${r}" | cut -d "+" -f2)

     # check the x-offset for being non-zero and if so
     # enable multimon support
     if [[ $x -ne 0 ]]; then
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
if [[ "${keyLayout}" == "de" ]]; then
   cmdArgs="$cmdArgs /kbd:layout:0x407" # German
else
   cmdArgs="$cmdArgs /kbd:layout:0x409" # US
fi

# add domain
if [[ "${domain}" != "NULL" ]]; then
  cmdArgs="$cmdArgs /d:${domain}"
else
  cmdArgs="$cmdArgs /d:FZR"
fi

# add username
if [[ "${username}" != "NULL" ]]; then
  cmdArgs="$cmdArgs /u:${username}"
elif [[ "${domain}" != "NULL" ]]; then
  cmdArgs="$cmdArgs /u:${domain}\\"
fi

# set the window title to the server name we connect to
cmdArgs="$cmdArgs /t:${username}@${serverName}"

# ignore the certificate in case of encryption
cmdArgs="$cmdArgs /cert:ignore"

# add the usb path as a local path. if TLSESSIONDATA is set
# we are in a thinlinc session and thus have to forward
# ${HOME}/thindrives/mnt instead
if [ -n "${TLSESSIONDATA}" ]; then
  mkdir -p "${TLSESSIONDATA}/drives"
  cmdArgs="$cmdArgs /drive:USB,${TLSESSIONDATA}/drives/"
else
  cmdArgs="$cmdArgs /drive:USB,/run/usbmount/"
fi

# enable sound redirection
cmdArgs="$cmdArgs /sound:sys:pulse"

# enable audio input redirection
cmdArgs="$cmdArgs /microphone:sys:pulse"

# performance optimization options
cmdArgs="$cmdArgs +multitransport +auto-reconnect +fonts +window-drag -menu-anims -themes +wallpaper +heartbeat /dynamic-resolution /gdi:hw /rfx /gfx:avc444 /video /network:auto /dvc:rdpecam"

# exception for old servers with weak security footprints
if [[ "${serverName}" == "fwpdev01" ]]; then
  cmdArgs="$cmdArgs /tls-seclevel:0"
fi

# if we are not in dtlogin mode we go and
# output the xfreerdp line that is to be executed
if [[ "${dtlogin}" != "true" ]]; then

  # add clipboard synchronization (only required in non-dtlogin mode)
  cmdArgs="$cmdArgs /clipboard"

  echo "${XFREERDP} ${cmdArgs} /v:${serverName}" >>"/tmp/xfreerdp-${USER}-$$.log" 2>&1
else
  # disable the full-screen toggling in case we are in dtlogin mode
  cmdArgs="$cmdArgs -toggle-fullscreen"
fi

# increase logging
cmdArgs="$cmdArgs /log-level:INFO"

# run xfreerdp finally
if [[ "${password}" != "NULL" ]]; then
  cmdArgs="$cmdArgs /from-stdin"
  echo "${XFREERDP} ${cmdArgs} /v:${serverName}" >>"/tmp/xfreerdp-${USER}-$$.log" 2>&1
  # shellcheck disable=SC2086
  echo "${password}" | ${XFREERDP} ${cmdArgs} /v:"${serverName}" >>"/tmp/xfreerdp-${USER}-$$.log" 2>&1 &
  res=$?
else
  # shellcheck disable=SC2086
  ${XFREERDP} ${cmdArgs} /v:"${serverName}" >>/tmp/xfreerdp-${USER}-$$.log 2>&1 &
  res=$?
fi

if [[ ${res} != 0 ]]; then
   cmdArgs=""
   echo "WARNING: couldn't start xfreerdp, retrying with other remote desktop"
fi

exit ${res}
