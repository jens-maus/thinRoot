#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Need a kernel version!"
    exit 1
fi

sed -i "s/BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE=\".*\"/BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE=\"$1\"/g" buildroot-external/configs/{intelnuc,tinkerboard}_defconfig
