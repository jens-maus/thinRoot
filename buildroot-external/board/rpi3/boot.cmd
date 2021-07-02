# modify bootargs, load kernel and boot it
# fallback defaults
setenv load_addr ${ramdisk_addr_r}
setenv console "tty2"
setenv loglevel "0"
setenv bootfs 1
setenv kernel_img "thinroot-Image"
setenv initrd "thinroot-initrd"

# output where we are booting from
itest.b ${devnum} == 0 && echo "U-boot loaded from SD"
itest.b ${devnum} == 1 && echo "U-boot loaded from eMMC"

# import environment from /boot/bootEnv.txt
if test -e ${devtype} ${devnum}:${bootfs} bootEnv.txt; then
  load ${devtype} ${devnum}:${bootfs} ${load_addr} bootEnv.txt
  env import -t ${load_addr} ${filesize}
fi

# load devicetree
fdt addr ${fdt_addr}
fdt get value bootargs /chosen bootargs

# set bootargs
setenv rootfs_str "/dev/ram0"
setenv bootargs "dwc_otg.lpm_enable=0 sdhci_bcm2708.enable_llm=0 console=${console} kgdboc=${console} scandelay=5 root=${rootfs_str} ro noswap rootfstype=ext4 elevator=deadline fsck.repair=yes lapic rootwait rootdelay=5 consoleblank=120 logo.nologo quiet loglevel=${loglevel} usb-storage.quirks=${usbstoragequirks} ${extraargs} ${bootargs}"

if env exists serverip; then
  echo "==== NETWORK BOOT ===="

  # init network
  dhcp

  # load initramfs
  tftp ${load_addr} ${initrd}
  setenv initrd_addr_r ${load_addr}

  # load kernel
  tftp ${kernel_addr_r} ${kernel_img}
else
  echo "==== LOCAL BOOT ===="
  # load initramfs
  load ${devtype} ${devnum}:${bootfs} ${load_addr} ${initrd}
  setenv initrd_addr_r ${load_addr}

  # load kernel
  setenv kernelfs ${bootfs}
  load ${devtype} ${devnum}:${kernelfs} ${kernel_addr_r} ${kernel_img}
fi

# boot kernel
booti ${kernel_addr_r} ${initrd_addr_r} ${fdt_addr}

echo "Boot failed, resetting..."
reset
