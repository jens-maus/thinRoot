#!/bin/sh

# Stop on error
set -e

BOARD_DIR="$(dirname "$0")"
#BOARD_NAME="$(basename "${BOARD_DIR}")"

# Use our own cmdline.txt+config.txt
cp "${BOARD_DIR}/cmdline.txt" "${BINARIES_DIR}/"
cp "${BOARD_DIR}/config.txt" "${BINARIES_DIR}/"
cp "${BOARD_DIR}/bootEnv.txt" "${BINARIES_DIR}/"

# README needs to be present, otherwise os_prefix is not
# prepended implicitly to the overlays' path, see:
# https://www.raspberrypi.com/documentation/computers/config_txt.html#overlay_prefix
touch "${BINARIES_DIR}/overlays/README" 2>/dev/null || true

# VERSION File
cp "${TARGET_DIR}/boot/VERSION" "${BINARIES_DIR}"

# create *.img file using genimage
support/scripts/genimage.sh -c "${BOARD_DIR}/genimage.cfg"
