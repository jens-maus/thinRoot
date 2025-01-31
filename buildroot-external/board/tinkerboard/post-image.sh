#!/bin/sh

# Stop on error
set -e

BOARD_DIR="$(dirname "$0")"
#BOARD_NAME="$(basename "${BOARD_DIR}")"

# bootEnv.txt file
cp "${BOARD_DIR}/bootEnv.txt" "${BINARIES_DIR}/"

# Use our own cmdline.txt
cp "${BOARD_DIR}/cmdline.txt" "${BINARIES_DIR}/"

# VERSION File
cp "${TARGET_DIR}/boot/VERSION" "${BINARIES_DIR}"

# create *.img file using genimage
support/scripts/genimage.sh -c "${BOARD_DIR}/genimage.cfg"
