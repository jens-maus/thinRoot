#!/bin/bash
# shellcheck shell=bash
#
# thinRoot boot server: /data preparation and assembly of the served
# TFTP/HTTP tree (${TFTP_ROOT}). The tree is rebuilt on every start and only
# contains generated files and symlinks into ${PAYLOAD_DIR} and ${DATA_DIR}.
#

# thinRoot boot entries: label, menu title, image (below thinroot/), cmdline
TR_LABELS=()
TR_TITLES=()
TR_IMAGES=()
TR_ARGS=()

add_thinroot_entries() {
  local label=$1 title=$2 image=$3
  TR_LABELS+=("${label}" "${label}-debug")
  TR_TITLES+=("${title}" "${title} (debug)")
  TR_IMAGES+=("${image}" "${image}")
  TR_ARGS+=("$(cmdline "${THINROOT_CMDLINE}")" "$(cmdline "${THINROOT_CMDLINE_DEBUG}")")
}

# create /data structure and example configuration on first start
prepare_data() {
  if [[ ! -w "${DATA_DIR}" ]]; then
    warn "${DATA_DIR} is not writable, skipping creation of the default configuration"
    return 0
  fi

  if [[ ! -e "${DATA_DIR}/conf" ]]; then
    cp -r "${SHARE_DIR}/default-data/conf" "${DATA_DIR}/conf"
    chown -R "${PUID}:${PGID}" "${DATA_DIR}/conf"
    log "created example thinRoot configuration in ${DATA_DIR}/conf"
  fi

  local dir
  for dir in boot extras images pkgs pxelinux.cfg; do
    if [[ ! -e "${DATA_DIR}/${dir}" ]]; then
      mkdir -p "${DATA_DIR}/${dir}"
      chown "${PUID}:${PGID}" "${DATA_DIR}/${dir}"
    fi
  done
}

# link each entry of <src dir> into <dst dir>, replacing existing entries
link_entries() {
  local src=$1 dst=$2 what=$3 entry name
  for entry in "${src}"/*; do
    [[ -e "${entry}" ]] || continue
    name=$(basename "${entry}")
    if [[ -e "${dst}/${name}" || -L "${dst}/${name}" ]]; then
      log "${what}: using custom ${name} from ${src}"
    fi
    ln -sfn "${entry}" "${dst}/${name}"
  done
}

link_bootloaders() {
  local f
  for f in "${SHARE_DIR}"/bootloader/*; do
    ln -s "${f}" "${TFTP_ROOT}/"
  done

  # aliases: generic names and file names used by the former tftpboot/ example
  ln -s lpxelinux.0 "${TFTP_ROOT}/pxelinux.0"
  ln -s lpxelinux.0 "${TFTP_ROOT}/pxeboot.0"
  ln -s ipxe.efi "${TFTP_ROOT}/ipxe.x86_64.efi"
  ln -s ipxe-i386.efi "${TFTP_ROOT}/ipxe.i386.efi"

  # Windows WDS style boot file name, as announced by some DHCP servers
  mkdir -p "${TFTP_ROOT}/Boot/x64"
  ln -s "../../${UEFI64_FILE}" "${TFTP_ROOT}/Boot/x64/wdsmgfw.efi"
  ln -s "${UEFI64_FILE}" "${TFTP_ROOT}/Boot\\x64\\wdsmgfw.efi"
}

link_release_images() {
  local f name short found=0
  for f in "${PAYLOAD_DIR}"/thinroot-*; do
    [[ -f "${f}" ]] || continue
    found=1
    name=$(basename "${f}")
    ln -s "${f}" "${TFTP_ROOT}/thinroot/${name}"
    # version independent name, e.g. thinroot-rpi4-kernel.img, so that
    # client configurations (bootEnv.txt) survive updates
    short=${name/-${THINROOT_VERSION}-/-}
    [[ "${short}" != "${name}" ]] && ln -sfn "${f}" "${TFTP_ROOT}/thinroot/${short}"
  done
  if [[ -e "${TFTP_ROOT}/thinroot/thinroot-generic-x86_64.img" ]]; then
    ln -sfn "$(readlink "${TFTP_ROOT}/thinroot/thinroot-generic-x86_64.img")" "${TFTP_ROOT}/thinroot/thinroot.img"
  fi
  if [[ ${found} -eq 0 ]]; then
    warn "this image contains no thinRoot release images (${PAYLOAD_DIR} is empty)"
  fi
}

# own images in /data/images: override bundled ones with the same name and
# add boot menu entries for additional x86_64 images
link_data_images() {
  local f name title label
  for f in "${DATA_DIR}"/images/*; do
    [[ -f "${f}" ]] || continue
    name=$(basename "${f}")
    if [[ ! "${name}" =~ ^[A-Za-z0-9._+-]+$ ]]; then
      warn "images: ignoring '${name}', only letters, digits and . _ + - are allowed in file names"
      continue
    fi
    if [[ -e "${TFTP_ROOT}/thinroot/${name}" ]]; then
      log "images: ${name} from ${DATA_DIR}/images replaces the bundled image"
    fi
    ln -sfn "${f}" "${TFTP_ROOT}/thinroot/${name}"

    case "${name}" in
      thinroot.img | *rpi[0-9]* | *-kernel.img | *-sdcard.img | *.sha256) continue ;;
      *.img) ;;
      *) continue ;;
    esac
    if [[ "${name}" == "thinroot-beta.img" ]]; then
      title="thinRoot beta"
    else
      title=${name%.img}
    fi
    label=$(sanitize_label "${name%.img}")
    case "${label}" in
      thinroot | thinroot-debug | local | memtest | memtest_efi | clonezilla | sysrescue | \
      pxelinux | shell | reboot | exit | failed | main_menu)
        label="img-${label}"
        ;;
    esac
    add_thinroot_entries "${label}" "${title}" "${name}"
  done
}

link_config() {
  local dir
  for dir in conf pkgs; do
    if [[ -d "${DATA_DIR}/${dir}" ]]; then
      ln -s "${DATA_DIR}/${dir}" "${TFTP_ROOT}/thinroot/${dir}"
    fi
  done
  if [[ ! -d "${DATA_DIR}/conf" ]]; then
    warn "${DATA_DIR}/conf does not exist, clients will boot without thinRoot configuration"
  fi
}

# rootfs overlays: /data/overlay<suffix>/ directories are packed into
# thinroot/overlay.pkg<suffix>; prebuilt /data/overlay.pkg<suffix> files
# are served as they are
build_overlays() {
  local dir name suffix out f
  for dir in "${DATA_DIR}"/overlay*/; do
    [[ -d "${dir}" ]] || continue
    dir=${dir%/}
    name=$(basename "${dir}")
    suffix=${name#overlay}
    out="${TFTP_ROOT}/thinroot/overlay.pkg${suffix}"
    if [[ -z "$(ls -A "${dir}")" ]]; then
      continue
    fi
    # no "./" entry: extracting it would change the permissions of / on the client
    (cd "${dir}" && find . -mindepth 1 -print0 | LC_ALL=C sort -z |
      tar -cJf "${out}" --null --no-recursion -T - --owner=root --group=root --numeric-owner)
    chmod 0644 "${out}"
    log "overlay: packed ${dir} into thinroot/overlay.pkg${suffix}"
  done
  for f in "${DATA_DIR}"/overlay.pkg*; do
    [[ -f "${f}" ]] || continue
    name=$(basename "${f}")
    if [[ -e "${TFTP_ROOT}/thinroot/${name}" ]]; then
      warn "overlay: ignoring ${f}, ${name} is already generated from a directory"
      continue
    fi
    ln -s "${f}" "${TFTP_ROOT}/thinroot/${name}"
  done
}

# optional tools (memtest, clonezilla, sysrescue) and other files to serve
link_extras() {
  local entry name
  for entry in "${DATA_DIR}"/extras/*; do
    [[ -e "${entry}" ]] || continue
    name=$(basename "${entry}")
    case "${name}" in
      boot | pxelinux.cfg | thinroot | healthz)
        warn "extras: ignoring ${entry}, '${name}' is reserved"
        continue
        ;;
    esac
    if [[ -e "${TFTP_ROOT}/${name}" || -L "${TFTP_ROOT}/${name}" ]]; then
      log "extras: ${name} from ${DATA_DIR}/extras replaces the bundled file"
    fi
    ln -sfn "${entry}" "${TFTP_ROOT}/${name}"
  done

  MEMTEST_BIOS=""
  MEMTEST_EFI=""
  local f
  for f in memtest64.bin mt86plus memtest.bin; do
    if [[ -f "${TFTP_ROOT}/memtest/${f}" ]]; then
      MEMTEST_BIOS="memtest/${f}"
      break
    fi
  done
  [[ -f "${TFTP_ROOT}/memtest/memtest64.efi" ]] && MEMTEST_EFI="memtest/memtest64.efi"

  HAVE_CLONEZILLA=false
  if [[ -f "${TFTP_ROOT}/clonezilla/live/vmlinuz" && -f "${TFTP_ROOT}/clonezilla/live/initrd.img" ]]; then
    HAVE_CLONEZILLA=true
  fi
  HAVE_SYSRESCUE=false
  if [[ -f "${TFTP_ROOT}/sysrescue/sysresccd/boot/x86_64/vmlinuz" &&
        -f "${TFTP_ROOT}/sysrescue/sysresccd/boot/x86_64/sysresccd.img" ]]; then
    HAVE_SYSRESCUE=true
  fi
}

build_tree() {
  mkdir -p "${TFTP_ROOT}"
  find "${TFTP_ROOT}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  mkdir -p "${TFTP_ROOT}/boot" "${TFTP_ROOT}/pxelinux.cfg" "${TFTP_ROOT}/thinroot"

  link_bootloaders
  link_release_images

  TR_LABELS=()
  TR_TITLES=()
  TR_IMAGES=()
  TR_ARGS=()
  add_thinroot_entries thinroot "thinRoot ${THINROOT_VERSION}" thinroot.img
  link_data_images

  link_config
  build_overlays
  link_extras

  if [[ ! -e "${TFTP_ROOT}/thinroot/thinroot.img" ]]; then
    warn "no thinroot/thinroot.img available: x86_64 clients cannot boot thinRoot" \
         "(put an image into ${DATA_DIR}/images/thinroot.img)"
  fi
}

# all labels that can be used as MENU_DEFAULT
menu_labels() {
  printf '%s\n' "${TR_LABELS[@]}" local
  [[ -n "${MEMTEST_BIOS}${MEMTEST_EFI}" ]] && echo memtest
  is_true "${HAVE_CLONEZILLA}" && echo clonezilla
  is_true "${HAVE_SYSRESCUE}" && echo sysrescue
  return 0
}

check_menu_default() {
  if ! menu_labels | grep -qxF "${MENU_DEFAULT}"; then
    warn "MENU_DEFAULT '${MENU_DEFAULT}' is not a boot menu entry" \
         "(available: $(menu_labels | tr '\n' ' ')), using 'thinroot'"
    MENU_DEFAULT=thinroot
  fi
}

# warn about served files the unprivileged services cannot read
check_permissions() {
  local count=0 f
  while IFS= read -r -d '' f; do
    if ((count < 20)); then
      warn "not readable for PUID ${PUID}/PGID ${PGID}: ${f}"
    fi
    count=$((count + 1))
  done < <(find -L "${TFTP_ROOT}" -type f \
             ! -perm -004 ! \( -user "${PUID}" -perm -400 \) ! \( -group "${PGID}" -perm -040 \) \
             -print0 2>/dev/null)
  if ((count > 0)); then
    warn "${count} file(s) cannot be served; fix their permissions or set PUID/PGID"
  fi
}
