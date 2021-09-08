#!/bin/sh

BOARD_DIR="$(dirname "$0")"
BOARD_NAME="$(basename "${BOARD_DIR}")"

# Use our own cmdline.txt+config.txt
cp "${BR2_EXTERNAL_THINROOT_PATH}/board/${BOARD_NAME}/cmdline.txt" "${BINARIES_DIR}/"
cp "${BR2_EXTERNAL_THINROOT_PATH}/board/${BOARD_NAME}/config.txt" "${BINARIES_DIR}/"

# VERSION File
cp "${TARGET_DIR}/boot/VERSION" "${BINARIES_DIR}"

# create *.img file using genimage
support/scripts/genimage.sh -c "${BR2_EXTERNAL_THINROOT_PATH}/board/${BOARD_NAME}/genimage.cfg"

exit $?
