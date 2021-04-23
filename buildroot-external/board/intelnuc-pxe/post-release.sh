#!/bin/bash

# Stop on error
set -e

#BOARD_DIR=${1}
PRODUCT=${2}
PRODUCT_VERSION=${3}
BOARD=$(echo "${PRODUCT}" | cut -d'_' -f2-)

# change into release dir
cd ./release

# copy the bzImage and create checksum
cp -a "../build-${PRODUCT}/images/bzImage" thinroot-${PRODUCT_VERSION}.img
sha256sum "thinroot-${PRODUCT_VERSION}.img" >thinroot-${PRODUCT_VERSION}.img.sha256

exit $?
