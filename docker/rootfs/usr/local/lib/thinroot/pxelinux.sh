#!/bin/bash
# shellcheck shell=bash
#
# thinRoot boot server: generation of the PXELINUX (legacy BIOS) menu in
# pxelinux.cfg/default. lpxelinux.0 loads the kernels via HTTP.
#

pxelinux_label() {
  local label=$1 title=$2
  echo "LABEL ${label}"
  echo "  MENU LABEL ${title}"
  [[ "${label}" == "${MENU_DEFAULT}" ]] && echo "  MENU DEFAULT"
  return 0
}

gen_pxelinux() {
  local out="${TFTP_ROOT}/pxelinux.cfg/default" timeout i
  timeout=$((MENU_TIMEOUT * 10))
  # TIMEOUT 0 waits forever, so a hidden menu needs at least 1/10s
  if ! is_true "${MENU_SHOW}" && ((timeout == 0)); then
    timeout=1
  fi

  {
    cat <<EOF
# thinRoot boot server - generated on container start, do not edit.
# Put an own default into ${DATA_DIR}/pxelinux.cfg/ to replace it, or add
# per-client files there (e.g. 01-52-54-00-12-34-56) containing:
#   INCLUDE pxelinux.cfg/default
#   ONTIMEOUT local

DEFAULT menu.c32
PROMPT 0
ALLOWOPTIONS 0
TIMEOUT ${timeout}
MENU TITLE thinRoot ${THINROOT_VERSION} - PXELINUX netboot
MENU AUTOBOOT Starting in # second{,s}...
EOF
    is_true "${MENU_SHOW}" || echo "MENU HIDDEN"
    echo

    for i in "${!TR_LABELS[@]}"; do
      pxelinux_label "${TR_LABELS[i]}" "${TR_TITLES[i]}"
      echo "  KERNEL ${BOOT_URL}thinroot/${TR_IMAGES[i]}"
      echo "  APPEND ${TR_ARGS[i]}"
      echo
    done

    pxelinux_label local "Boot from local disk"
    echo "  LOCALBOOT 0"
    echo

    if [[ -n "${MEMTEST_BIOS}" ]] || is_true "${HAVE_CLONEZILLA}" || is_true "${HAVE_SYSRESCUE}"; then
      echo "MENU SEPARATOR"
      echo
    fi
    if [[ -n "${MEMTEST_BIOS}" ]]; then
      pxelinux_label memtest "Memtest86+"
      echo "  KERNEL ${BOOT_URL}${MEMTEST_BIOS}"
      echo
    fi
    if is_true "${HAVE_CLONEZILLA}"; then
      pxelinux_label clonezilla "Clonezilla"
      echo "  KERNEL ${BOOT_URL}clonezilla/live/vmlinuz"
      echo "  APPEND initrd=${BOOT_URL}clonezilla/live/initrd.img boot=live config noswap nolocales edd=on nomodeset vga=788 nosplash noprompt fetch=${BOOT_URL}clonezilla/live/filesystem.squashfs"
      echo
    fi
    if is_true "${HAVE_SYSRESCUE}"; then
      pxelinux_label sysrescue "SystemRescue"
      echo "  KERNEL ${BOOT_URL}sysrescue/sysresccd/boot/x86_64/vmlinuz"
      echo "  APPEND initrd=${BOOT_URL}sysrescue/sysresccd/boot/x86_64/sysresccd.img ip=dhcp archisobasedir=sysresccd archiso_http_srv=${BOOT_URL}sysrescue/ checksum"
      echo
    fi

    echo "MENU SEPARATOR"
    echo
    echo "LABEL ipxe"
    echo "  MENU LABEL Switch to iPXE"
    echo "  KERNEL ipxe.lkrn"
  } >"${out}"

  link_entries "${DATA_DIR}/pxelinux.cfg" "${TFTP_ROOT}/pxelinux.cfg" "pxelinux.cfg"
}
