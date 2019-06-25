#!/bin/sh

# Load up all .env files in /etc/env.d
set -o allexport
for i in $(ls /etc/env.d/*.env); do 
  source $i
done
set +o allexport
