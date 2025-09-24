#!/bin/sh
# shellcheck shell=dash disable=SC3014
#
# This script can be run to control the pulseaudio speaker
# output and microphone input to set the volume up/down,
# mute/unmute toggle and to show that via an optional
# OSD display function.
#
# Copyright (C) 2025 Jens Maus <mail@jens-maus.de>
#

# wrapper to call pactl as truser
pactl()
{
  /bin/su - truser -c "/usr/bin/pactl ${1} ${2} ${3}"
}

# get the volume and return the volume in %
pa_get_sink_volume()
{
  VOLUME=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]\+%' | head -n1 | tr -d %)
}

# get the volume and return the volume in %
pa_get_source_volume()
{
  VOLUME=$(pactl get-source-volume @DEFAULT_SOURCE@ | grep -o '[0-9]\+%' | head -n1 | tr -d %)
}

# get the mute mode of the output sink
pa_get_sink_mute()
{
  MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print ($2=="yes")?1:0}')
}

# get the mute mode of the input source
pa_get_source_mute()
{
  MUTE=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print ($2=="yes")?1:0}')
}

# function to optionally output the current
# speaker volume or source input in percentage
osd_notify()
{
  if [ -x /usr/bin/osd_cat ]; then
    if [ "${MUTE}" == "1" ]; then
      VOLUME="0"
      MUTETEXT=" (mute)"
    else
      MUTETEXT=""
    fi

    if [ "${TARGET}" == "speaker" ]; then
      COLOR=green
      TEXT="VOL:"
    elif [ "${TARGET}" == "mic" ]; then
      COLOR=orange
      TEXT="MIC:"
    fi

    # kill previous osd_cat
    pkill /usr/bin/osd_cat
    export LANG=en_US.UTF-8
    export DISPLAY=:0
    /usr/bin/osd_cat -A center -p bottom -f '-*-fixed-bold-r-*-*-30-*-*-*-*-*-*-*' -c "${COLOR}" -s 5 -d 3 --barmode=percentage -P "${VOLUME}" -T "${TEXT} ${VOLUME}%${MUTETEXT}" &
  fi
}

############################################
# main starts here

TARGET=${1}
CMD=${2}

if [ "${TARGET}" == "speaker" ]; then
  if [ "${CMD}" == "toggle" ]; then
    pactl set-sink-mute @DEFAULT_SINK@ "${CMD}"
  else
    pactl set-sink-volume @DEFAULT_SINK@ "${CMD}"
    pactl set-sink-mute @DEFAULT_SINK@ 0
  fi
  pa_get_sink_volume
  pa_get_sink_mute
elif [ "${TARGET}" == "mic" ]; then
  if [ "${CMD}" == "toggle" ]; then
    pactl set-source-mute @DEFAULT_SOURCE@ "${CMD}"
  else
    pactl set-source-volume @DEFAULT_SOURCE@ "${CMD}"
    pactl set-source-mute @DEFAULT_SOURCE@ 0
  fi
  pa_get_source_volume
  pa_get_source_mute
fi

osd_notify

exit 0
