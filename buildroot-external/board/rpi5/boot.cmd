# modify bootargs, load kernel and boot it
# fallback defaults
setenv load_addr ${ramdisk_addr_r}
setenv console "tty2"
setenv loglevel "0"
setenv bootfs 1
setenv kernel_img "thinroot-Image"
setenv initrd "thinroot-initrd"
setenv usbstoragequirks "174c:55aa:u,2109:0715:u,152d:0578:u,152d:0579:u,152d:1561:u,174c:0829:u,14b0:0206:u,174c:55aa:u"

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
setenv bootargs "dwc_otg.lpm_enable=0 sdhci_bcm2708.enable_llm=0 console=${console} root=${rootfs_str} ro noswap rootfstype=ext4 fsck.repair=yes rootwait rootdelay=5 consoleblank=120 logo.nologo quiet loglevel=${loglevel} init_on_alloc=1 init_on_free=1 slab_nomerge iomem=relaxed net.ifnames=0 usb-storage.quirks=${usbstoragequirks} ${extraargs} ${bootargs}"

if env exists bootserver; then
  echo "==== NETWORK BOOT ===="

  # init network
  dhcp
  setenv serverip ${bootserver}

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
