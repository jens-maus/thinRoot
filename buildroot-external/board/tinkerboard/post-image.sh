#!/bin/sh

#MKIMAGE=${HOST_DIR}/usr/bin/mkimage
BOARD_DIR="$(dirname "$0")"
BOARD_NAME="$(basename "${BOARD_DIR}")"

#
# VERSION File
#
cp "${TARGET_DIR}/boot/VERSION" "${BINARIES_DIR}"

# create *.img file using genimage
support/scripts/genimage.sh -c "${BR2_EXTERNAL_EQ3_PATH}/board/${BOARD_NAME}/genimage.cfg"

exit $?
