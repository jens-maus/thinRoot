#!/bin/sh
#
# This script is executed by a udev rule and will make
# sure that the pa-update-default-sink script is executed
# as 'tsuser' and also in a subshell
#

(/bin/su - truser -c /bin/pa-update-default-sink.sh) &
