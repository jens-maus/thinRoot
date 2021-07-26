#!/bin/sh
# shellcheck shell=dash disable=SC1090

# Load up all .env files in /etc/env.d
set -o allexport
for i in /etc/env.d/*.env; do 
  [ -e "${i}" ] || break
  . "${i}"
done
set +o allexport
