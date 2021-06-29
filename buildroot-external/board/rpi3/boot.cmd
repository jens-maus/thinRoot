# modify bootargs, load kernel and boot it
# fallback defaults
setenv load_addr ${ramdisk_addr_r}
setenv console "tty2"
setenv loglevel "0"
setenv bootfs 1
setenv rootfs 2
setenv userfs 3
setenv kernel_img "zImage"

# output where we are booting from
itest.b ${devnum} == 0 && echo "U-boot loaded from SD"
itest.b ${devnum} == 1 && echo "U-boot loaded from eMMC"

# import environment from /boot/bootEnv.txt
if test -e ${devtype} ${devnum}:${bootfs} bootEnv.txt; then
  load ${devtype} ${devnum}:${bootfs} ${load_addr} bootEnv.txt
  env import -t ${load_addr} ${filesize}
fi

echo "==== NORMAL BOOT ===="
# get partuuid of root_num
part uuid ${devtype} ${devnum}:${rootfs} partuuid
setenv rootfs_str "PARTUUID=${partuuid}"
setenv initrd_addr_r "-"
setenv kernelfs ${rootfs}

# load devicetree
fdt addr ${fdt_addr}
fdt get value bootargs /chosen bootargs

# set bootargs
setenv bootargs "dwc_otg.lpm_enable=0 sdhci_bcm2708.enable_llm=0 console=${console} kgdboc=${console} scandelay=5 root=${rootfs_str} ro noswap rootfstype=ext4 elevator=deadline fsck.repair=yes lapic rootwait rootdelay=5 consoleblank=120 logo.nologo quiet loglevel=${loglevel} usb-storage.quirks=${usbstoragequirks} ${extraargs} ${bootargs}"

# load kernel
load ${devtype} ${devnum}:${kernelfs} ${kernel_addr_r} ${kernel_img}

# boot kernel
bootz ${kernel_addr_r} ${initrd_addr_r} ${fdt_addr}
