# fallback defaults
setenv ramdisk_addr_r "0x21000000"
setenv load_addr "0x39000000"
setenv console "tty2"
setenv loglevel "0"
setenv bootfs 1
setenv kernel_img "thinroot-Image"
setenv initrd "thinroot-initrd"
setenv overlays ""
setenv usbstoragequirks "0x2537:0x1066:u,0x2537:0x1068:u"

echo "Boot script loaded from ${devtype} ${devnum}"

# import environment from /boot/bootEnv.txt
if test -e ${devtype} ${devnum}:${bootfs} bootEnv.txt; then
  load ${devtype} ${devnum}:${bootfs} ${load_addr} bootEnv.txt
  env import -t ${load_addr} ${filesize}
fi

# load kernel cmdline from /boot/cmdline.txt
fileenv ${devtype} ${devnum}:${bootfs} ${load_addr} cmdline.txt cmdline

# Load device tree
if test "$devnum" = "0"; then
  setenv fdtfile "rk3288-tinker-s.dtb"
else
  setenv fdtfile "rk3288-tinker.dtb"
fi

echo "Loading standard device tree ${fdtfile}"
load ${devtype} ${devnum}:${bootfs} ${fdt_addr_r} ${fdtfile}
fdt addr ${fdt_addr_r}

# load dt overlays
fdt resize 65536
for overlay_file in ${overlays}; do
  if load ${devtype} ${devnum}:${bootfs} ${load_addr} overlays/${overlay_file}.dtbo; then
    echo "Applying kernel provided DT overlay ${overlay_file}.dtbo"
    fdt apply ${load_addr} || setenv overlay_error "true"
  fi
done
if test "${overlay_error}" = "true"; then
  echo "Error applying DT overlays, restoring original DT"
  load ${devtype} ${devnum}:${bootfs} ${fdt_addr_r} ${fdtfile}
fi

# set bootargs
setenv rootfs_str "/dev/ram0"
setenv bootargs "console=${console} root=${rootfs_str} ro rootfstype=ext4 fsck.repair=yes rootwait rootdelay=5 consoleblank=120 quiet loglevel=${loglevel} init_on_alloc=1 init_on_free=1 slab_nomerge iomem=relaxed net.ifnames=0 usb-storage.quirks=${usbstoragequirks} ${cmdline} ${bootargs}"

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
bootz ${kernel_addr_r} ${initrd_addr_r} ${fdt_addr_r}

echo "Boot failed, resetting..."
reset
