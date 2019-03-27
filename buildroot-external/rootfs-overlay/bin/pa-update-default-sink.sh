#!/bin/sh
#
# This script will be run by acpi and udev and will set the correct audio output
# depending on which audio outputs are currently available.
#
# First we check if headphones are plugged-in if not
# we check if USB sound is plugged in
# Otherwise setting HDMI as default or even if there is no HDMI
# we use the first card listed
#
# Copyright (C) 2014-2019 Jens Maus <mail@jens-maus.de>
#

#. ${TS_GLOBAL}

# function to get the name of a specific audio output sink
getSinkName()
{
  pattern="${1}"

  # now iterate through all sinks and grab its information
  numsinks=$(pactl list short sinks | awk '{ print $1 }')
  for i in ${numsinks}; do
    sinkinfo=$(echo "${painfo}" | sed -n "/^Sink #${i}$/,/Formats:/p")
    searchres=$(echo "${sinkinfo}" | grep -e ${pattern})
    if [ -n "${searchres}" ]; then
      # output the sink name
      echo "${painfo}" | sed -n "/^Sink #${i}$/,/Formats:/p" | grep "Name: " | awk '{ print $2 }'
      break
    fi
  done
}

# function to get the name of a specific audio source
getSourceName()
{
  pattern="${1}"

  # now iterate through all sources and grab its information
  numsrcs=$(pactl list short sources | awk '{ print $1 }')
  for i in ${numsrcs}; do
    srcinfo=$(echo "${painfo}" | sed -n "/^Source #${i}$/,/Formats:/p")
    searchres=$(echo "${srcinfo}" | grep -e ${pattern})
    if [ -n "${searchres}" ]; then
      # output the src name
      echo "${painfo}" | sed -n "/^Source #${i}$/,/Formats:/p" | grep "Name: " | awk '{ print $2 }'
      break
    fi
  done
}

# function that allows to identify an active card profile
# and use it accordingly.
setActiveCardProfile()
{
  cardnum="${1}"

  # now iterate through all cards and output the first profile that
  # is set as available
  cardinfo=$(pactl list cards | sed -n "/^Card #${cardnum}$/,/^$/p")

  # find the first
  actport=$(echo "${cardinfo}" | grep -e ".*:.*(.*,.*available)" | grep -v "not available" | head -n 1 | awk '{ print $1 }')

  # check if actport is empty
  if [ -n "${actport}" ]; then
    # not empty, identify the profile name
    actprofile=$(echo "${cardinfo}" | sed -n "/\w*${actport}.*)/,/Part of profile/p" | tail -n1 | awk -F': ' '{ print $2 }' | awk -F',' '{ print $1 }')
  else
    # empty, so lets get the first profile
    actprofile=$(echo "${cardinfo}" | sed -n "/\tPorts:/,/^$/p" | grep "Part of profile" | head -n1 | awk -F': ' '{ print $2 }' | awk -F',' '{ print $1 }')
  fi

  # set the profile as the active one for that card
  pactl set-card-profile ${cardnum} ${actprofile}+input:analog-stereo >/dev/null 2>&1
  if [ $? -eq 1 ]; then
    pactl set-card-profile ${cardnum} ${actprofile}
  fi
}

############################################
# main starts here

# first we make sure we have all possible sinks (HDMI+analog stereo) before setting/rerouting
# the audio streams to a different sink.
for inum in $(pactl list short cards | cut -f1); do
  setActiveCardProfile ${inum}
done

# get all information pactl list can provide us about our sinks
painfo=$(pactl list sinks)

sinkname=""
# check for the headphones first
if [ -n "`echo \"${painfo}\" | grep -e Headphones.*priority | grep -v 'not available'`" ]; then
  # headphones are plugged in and available, lets find out the sink name
  sinkname=$(getSinkName "Headphones.*priority")
else
  # check for USB sound devices (Speakers)
  if [ -n "`echo \"${painfo}\" | grep -e Speakers.*priority | grep -v 'not available'`" ]; then
    sinkname=$(getSinkName "Speakers.*priority")
  else
    # check for HDMI devices
    if [ -n "`echo \"${painfo}\" | grep -e HDMI.*priority`" ]; then
      sinkname=$(getSinkName "HDMI.*priority")
    fi
  fi
fi

# check if we have the name of the sink
if [ -n "${sinkname}" ]; then

  # move all sink inputs to the new sink
  for inum in $(pactl list short sink-inputs | cut -f1); do
    pactl move-sink-input ${inum} "${sinkname}"
  done

  # make sure that the new sink is unmuted
  pactl set-sink-mute ${sinkname} 0

  # make sure the audio output is set to the AUDIO_LEVEL volume level
  pactl set-sink-volume ${sinkname} ${AUDIO_LEVEL}%

  # set the new sink as the new default
  pactl set-default-sink ${sinkname}

else
  echo "WARNING: no available output sink found"
  exit 2
fi

# get all information pactl list can provide us about our audio sources
painfo=$(pactl list sources)

srcname=""
# check for a microphone first
if [ -n "`echo \"${painfo}\" | grep -e Microphone.*priority | grep -v 'not available'`" ]; then
  # microphone is plugged in and available, lets find out the sink name
  srcname=$(getSourceName "Microphone.*priority")

  # make sure the microphone is set to the MIC_LEVEL volume and unmuted
  pactl set-source-mute ${srcname} 0
  pactl set-source-volume ${srcname} ${MIC_LEVEL}%
fi

exit 0
