#!/bin/bash

# Stop on error
set -e

#BOARD_DIR=${1}
PRODUCT=${2}
PRODUCT_VERSION=${3}
#BOARD=$(echo "${PRODUCT}" | cut -d'_' -f2-)

# change into release dir
cd ./release

# copy the bzImage and create checksum
cp -a "../build-${PRODUCT}/images/Image" "thinroot-${PRODUCT_VERSION}-${PRODUCT}-kernel.img"
sha256sum "thinroot-${PRODUCT_VERSION}-${PRODUCT}-kernel.img" >"thinroot-${PRODUCT_VERSION}-${PRODUCT}-kernel.img.sha256"
cp -a "../build-${PRODUCT}/images/rootfs.cpio.uboot" "thinroot-${PRODUCT_VERSION}-${PRODUCT}.img"
sha256sum "thinroot-${PRODUCT_VERSION}-${PRODUCT}.img" >"thinroot-${PRODUCT_VERSION}-${PRODUCT}.img.sha256"
cp -a "../build-${PRODUCT}/images/sdcard.img" "thinroot-${PRODUCT_VERSION}-${PRODUCT}-sdcard.img"
sha256sum "thinroot-${PRODUCT_VERSION}-${PRODUCT}-sdcard.img" >"thinroot-${PRODUCT_VERSION}-${PRODUCT}-sdcard.img.sha256"

# create manifest file with checksum+sizes
rm -f "thinroot-${PRODUCT_VERSION}-${PRODUCT}.mf"

# shellcheck disable=SC2129
echo "$(stat -c %s "./thinroot-${PRODUCT_VERSION}-${PRODUCT}.img") $(cat "thinroot-${PRODUCT_VERSION}-${PRODUCT}.img.sha256")" >>"thinroot-${PRODUCT_VERSION}-${PRODUCT}.mf"
echo "$(stat -c %s "./thinroot-${PRODUCT_VERSION}-${PRODUCT}-kernel.img") $(cat "thinroot-${PRODUCT_VERSION}-${PRODUCT}-kernel.img.sha256")" >>"thinroot-${PRODUCT_VERSION}-${PRODUCT}.mf"
echo "$(stat -c %s "./thinroot-${PRODUCT_VERSION}-${PRODUCT}-sdcard.img") $(cat "thinroot-${PRODUCT_VERSION}-${PRODUCT}-sdcard.img.sha256")" >>"thinroot-${PRODUCT_VERSION}-${PRODUCT}.mf"
