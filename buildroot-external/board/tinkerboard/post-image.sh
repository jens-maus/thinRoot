#!/bin/sh

#MKIMAGE=${HOST_DIR}/usr/bin/mkimage
BOARD_DIR="$(dirname "$0")"
BOARD_NAME="$(basename "${BOARD_DIR}")"

# bootEnv.txt file
cp "${BR2_EXTERNAL_THINROOT_PATH}/board/${BOARD_NAME}/bootEnv.txt" "${BINARIES_DIR}/"

# VERSION File
cp "${TARGET_DIR}/boot/VERSION" "${BINARIES_DIR}"

# create *.img file using genimage
support/scripts/genimage.sh -c "${BR2_EXTERNAL_THINROOT_PATH}/board/${BOARD_NAME}/genimage.cfg"

exit $?
