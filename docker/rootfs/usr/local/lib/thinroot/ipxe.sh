#!/bin/bash
# shellcheck shell=bash disable=SC2016
#
# thinRoot boot server: generation of the iPXE scripts in boot/
#
# Boot flow: iPXE (embedded script) -> boot/net.ipxe -> boot/net.cfg
#            -> boot/mac-<mac>.ipxe (optional) -> boot/menu-main.ipxe
#

gen_ipxe_net() {
  local out="${TFTP_ROOT}/boot/net.ipxe"
  {
    echo '#!ipxe'
    echo '# thinRoot boot server - generated on container start, do not edit.'
    echo "# Put an own net.ipxe into ${DATA_DIR}/boot/ to replace it."
    echo
    echo 'chain --autofree net.cfg ||'
    echo
    if is_true "${MENU_SHOW}"; then
      echo 'set showmenu 1'
      echo "set menu-timeout $((MENU_TIMEOUT * 1000))"
    elif ((MENU_TIMEOUT > 0)); then
      echo '# show the boot menu if SPACE is pressed'
      echo "prompt --timeout $((MENU_TIMEOUT * 1000)) --key 0x20 Press SPACE for the thinRoot boot menu... && set showmenu 1 ||"
    fi
    echo
    echo 'isset ${showmenu} && chain --autofree ${boot-url}${boot-dir}net.theme ||'
    echo
    echo '# per-client script, e.g. boot/mac-525400123456.ipxe'
    echo 'chain --replace --autofree ${boot-url}${boot-dir}mac-${mac:hexraw}.ipxe ||'
    echo
    echo 'chain --replace --autofree ${boot-menu}'
  } >"${out}"

  cat >"${TFTP_ROOT}/boot/net.cfg" <<EOF
#!ipxe
# thinRoot boot server - generated on container start, do not edit.

cpuid --ext 29 && set arch x64 || set arch x32
cpuid --ext 29 && set archl amd64 || set archl i386

set boot-server ${SERVER_IP}
set boot-url ${BOOT_URL}
set boot-dir boot/
set boot-menu \${boot-url}\${boot-dir}menu-main.ipxe
set thinroot-version ${THINROOT_VERSION}
EOF

  cat >"${TFTP_ROOT}/boot/net.theme" <<'EOF'
#!ipxe
# thinRoot boot server - boot menu theme

console --x 1024 --y 768 --picture ${boot-url}${boot-dir}pxe-banner.png --keep --left 40 --right 290 --top 32 --bottom 48 ||
colour --rgb 0xf5f219 7 ||
colour --rgb 0x75f658 6 ||
EOF
  cp "${SHARE_DIR}/static/boot/pxe-banner.png" "${TFTP_ROOT}/boot/pxe-banner.png"
}

gen_ipxe_menu() {
  local out="${TFTP_ROOT}/boot/menu-main.ipxe" i
  {
    cat <<EOF
#!ipxe
# thinRoot boot server - generated on container start, do not edit.
# Put an own menu-main.ipxe into ${DATA_DIR}/boot/ to replace it, or select
# another default entry for single clients with ${DATA_DIR}/boot/mac-<mac>.ipxe:
#   #!ipxe
#   set menu-default local
#   chain \${boot-menu}

isset \${menu-default} || set menu-default ${MENU_DEFAULT}
isset \${menu-timeout} || set menu-timeout 0
isset \${showmenu} || goto \${menu-default}

:main_menu
menu thinRoot ${THINROOT_VERSION} - iPXE netboot (\${archl}, \${platform})
item --gap --             ------------------------ thinRoot ------------------------
EOF
    for i in "${!TR_LABELS[@]}"; do
      printf 'item %-22s %s\n' "${TR_LABELS[i]}" "${TR_TITLES[i]}"
    done
    printf 'item %-22s %s\n' local "Boot from local disk"

    if [[ -n "${MEMTEST_BIOS}${MEMTEST_EFI}" ]] || is_true "${HAVE_CLONEZILLA}" || is_true "${HAVE_SYSRESCUE}"; then
      echo 'item --gap --             ------------------------- Tools --------------------------'
      if [[ -n "${MEMTEST_BIOS}" && -n "${MEMTEST_EFI}" ]]; then
        printf 'item %-22s %s\n' memtest "Memtest86+"
      elif [[ -n "${MEMTEST_BIOS}" ]]; then
        printf 'iseq ${platform} pcbios && item %-22s %s ||\n' memtest "Memtest86+"
      elif [[ -n "${MEMTEST_EFI}" ]]; then
        printf 'iseq ${platform} efi && item %-22s %s ||\n' memtest "Memtest86+"
      fi
      is_true "${HAVE_CLONEZILLA}" && printf 'item %-22s %s\n' clonezilla "Clonezilla"
      is_true "${HAVE_SYSRESCUE}" && printf 'item %-22s %s\n' sysrescue "SystemRescue"
    fi

    echo 'item --gap --             ------------------------ Advanced ------------------------'
    printf 'iseq ${platform} pcbios && item %-22s %s ||\n' pxelinux "Switch to PXELINUX boot menu"
    [[ -n "${ADMIN_PASSWORD}" ]] && printf 'item %-22s %s\n' shell "iPXE shell (admin)"
    printf 'item %-22s %s\n' reboot "Reboot"
    printf 'item %-22s %s\n' exit "Exit iPXE"
    echo 'choose --timeout ${menu-timeout} --default ${menu-default} target && goto ${target} || goto main_menu'
    echo

    cat <<'EOF'
:failed
echo Boot failed, returning to the boot menu...
sleep 5
set showmenu 1
set menu-timeout 0
goto main_menu

:local
iseq ${platform} pcbios && sanboot --no-describe --drive 0x80 ||
exit

:reboot
reboot

:exit
exit

:pxelinux
set 209:string pxelinux.cfg/default
set 210:string tftp://${boot-server}/
chain tftp://${boot-server}/pxelinux.0 || goto failed

EOF

    if [[ -n "${ADMIN_PASSWORD}" ]]; then
      cat <<EOF
:shell
login || goto main_menu
iseq \${password} ${ADMIN_PASSWORD} || goto main_menu
clear password
echo Type 'exit' to return to the boot menu
shell
goto main_menu

EOF
    fi

    for i in "${!TR_LABELS[@]}"; do
      cat <<EOF
:${TR_LABELS[i]}
kernel \${boot-url}thinroot/${TR_IMAGES[i]} BOOT_IMAGE=\${boot-url}thinroot/${TR_IMAGES[i]} ${TR_ARGS[i]} || goto failed
boot || goto failed

EOF
    done

    if [[ -n "${MEMTEST_BIOS}${MEMTEST_EFI}" ]]; then
      echo ':memtest'
      echo 'iseq ${platform} efi && goto memtest_efi ||'
      if [[ -n "${MEMTEST_BIOS}" ]]; then
        echo "kernel \${boot-url}${MEMTEST_BIOS} || goto failed"
        echo 'boot || goto failed'
      fi
      echo 'goto failed'
      echo ':memtest_efi'
      if [[ -n "${MEMTEST_EFI}" ]]; then
        echo "chain \${boot-url}${MEMTEST_EFI} || goto failed"
      fi
      echo 'goto failed'
      echo
    fi

    if is_true "${HAVE_CLONEZILLA}"; then
      cat <<'EOF'
:clonezilla
kernel ${boot-url}clonezilla/live/vmlinuz initrd=initrd.img boot=live config noswap nolocales edd=on nomodeset vga=788 nosplash noprompt fetch=${boot-url}clonezilla/live/filesystem.squashfs || goto failed
initrd ${boot-url}clonezilla/live/initrd.img || goto failed
boot || goto failed

EOF
    fi

    if is_true "${HAVE_SYSRESCUE}"; then
      cat <<'EOF'
:sysrescue
kernel ${boot-url}sysrescue/sysresccd/boot/x86_64/vmlinuz initrd=sysresccd.img ip=dhcp archisobasedir=sysresccd archiso_http_srv=${boot-url}sysrescue/ checksum || goto failed
initrd ${boot-url}sysrescue/sysresccd/boot/x86_64/sysresccd.img || goto failed
boot || goto failed

EOF
    fi
  } >"${out}"
}

gen_ipxe() {
  gen_ipxe_net
  gen_ipxe_menu
  link_entries "${DATA_DIR}/boot" "${TFTP_ROOT}/boot" "boot"
}
