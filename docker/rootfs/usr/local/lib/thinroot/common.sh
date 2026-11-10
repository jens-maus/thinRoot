#!/bin/bash
# shellcheck shell=bash disable=SC2034
#
# thinRoot boot server: shared helpers and settings
# (the variables set here are used by the other modules)
#

# fixed paths
DATA_DIR=/data
TFTP_ROOT=/srv/tftpboot
RUN_DIR=/run/thinroot
SHARE_DIR=/usr/share/thinroot
PAYLOAD_DIR=/opt/thinroot

log() { echo "[thinroot] $*"; }
warn() { echo "[thinroot] WARNING: $*" >&2; }
die() {
  echo "[thinroot] ERROR: $*" >&2
  exit 1
}

is_true() {
  case "${1,,}" in
    1 | y | yes | true | on) return 0 ;;
    *) return 1 ;;
  esac
}

is_ipv4() {
  local IFS=. octet
  # shellcheck disable=SC2206
  local -a parts=($1)
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  for octet in "${parts[@]}"; do
    ((octet <= 255)) || return 1
  done
}

ip2int() {
  local IFS=.
  # shellcheck disable=SC2206
  local -a o=($1)
  echo $(((o[0] << 24) | (o[1] << 16) | (o[2] << 8) | o[3]))
}

int2ip() {
  echo "$((($1 >> 24) & 255)).$((($1 >> 16) & 255)).$((($1 >> 8) & 255)).$(($1 & 255))"
}

# network address of <ip> with <prefix length>
network_of() {
  local mask=$(((0xffffffff << (32 - $2)) & 0xffffffff))
  int2ip $(($(ip2int "$1") & mask))
}

# first IPv4 source address used for outgoing traffic
detect_server_ip() {
  ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p' | head -n1
}

# prefix length of the interface holding <ip>
detect_prefix() {
  ip -o -4 addr show 2>/dev/null | awk -v ip="$1" '{ split($4, a, "/"); if (a[1] == ip) { print a[2]; exit } }'
}

# load settings from the environment, apply defaults and validate them
load_settings() {
  : "${SERVER_IP:=}"
  : "${HTTP_PORT:=80}"
  : "${BOOT_URL:=}"
  : "${DHCP_MODE:=none}"
  : "${DHCP_PROXY_SUBNET:=}"
  : "${DHCP_RANGE:=}"
  : "${DHCP_ROUTER:=}"
  : "${DHCP_DNS:=}"
  : "${DHCP_DOMAIN:=}"
  : "${DHCP_AUTHORITATIVE:=false}"
  : "${INTERFACE:=}"
  : "${TFTP_SINGLE_PORT:=false}"
  : "${LEGACY_BOOTLOADER:=pxelinux}"
  : "${UEFI_BOOTLOADER:=snponly}"
  : "${MENU_DEFAULT:=thinroot}"
  : "${MENU_TIMEOUT:=4}"
  : "${MENU_SHOW:=false}"
  : "${ADMIN_PASSWORD:=}"
  : "${THINROOT_CMDLINE:=console=tty2 noswap noinitrd consoleblank=120 init_on_alloc=1 init_on_free=0 slab_nomerge net.ifnames=0 intel_iommu=igfx_off quiet loglevel=0}"
  : "${THINROOT_CMDLINE_DEBUG:=console=tty1 noswap noinitrd init_on_alloc=1 init_on_free=0 slab_nomerge net.ifnames=0 intel_iommu=igfx_off loglevel=8 debug}"
  : "${THINROOT_CMDLINE_EXTRA:=}"
  : "${PUID:=1000}"
  : "${PGID:=1000}"
  : "${HTTP_ACCESS_LOG:=true}"
  : "${HTTP_AUTOINDEX:=false}"
  : "${LOG_LEVEL:=info}"

  # server address used in all generated boot URLs
  if [[ -z "${SERVER_IP}" ]]; then
    SERVER_IP=$(detect_server_ip)
    [[ -n "${SERVER_IP}" ]] || die "SERVER_IP not set and no IPv4 address could be detected"
    log "SERVER_IP not set, using detected address ${SERVER_IP}" \
        "(set SERVER_IP explicitly when not using host networking)"
  fi
  is_ipv4 "${SERVER_IP}" || die "SERVER_IP '${SERVER_IP}' is not a valid IPv4 address"

  [[ "${HTTP_PORT}" =~ ^[0-9]+$ ]] || die "HTTP_PORT '${HTTP_PORT}' is not a number"
  if [[ -z "${BOOT_URL}" ]]; then
    BOOT_URL="http://${SERVER_IP}"
    [[ "${HTTP_PORT}" != "80" ]] && BOOT_URL+=":${HTTP_PORT}"
  fi
  BOOT_URL="${BOOT_URL%/}/"

  [[ "${MENU_TIMEOUT}" =~ ^[0-9]+$ ]] || die "MENU_TIMEOUT '${MENU_TIMEOUT}' is not a number (seconds)"
  [[ "${PUID}" =~ ^[0-9]+$ && "${PGID}" =~ ^[0-9]+$ ]] || die "PUID/PGID must be numeric"
  [[ "${ADMIN_PASSWORD}" =~ ^[A-Za-z0-9._+-]*$ ]] ||
    die "ADMIN_PASSWORD may only contain letters, digits and . _ + -"

  case "${LEGACY_BOOTLOADER}" in
    pxelinux) LEGACY_FILE=pxelinux.0 ;;
    ipxe) LEGACY_FILE=undionly.kpxe ;;
    *) die "LEGACY_BOOTLOADER must be 'pxelinux' or 'ipxe'" ;;
  esac
  case "${UEFI_BOOTLOADER}" in
    snponly) UEFI64_FILE=snponly.efi ;;
    ipxe) UEFI64_FILE=ipxe.efi ;;
    *) die "UEFI_BOOTLOADER must be 'snponly' or 'ipxe'" ;;
  esac
  UEFI32_FILE=ipxe-i386.efi

  case "${DHCP_MODE}" in
    none) ;;
    proxy)
      if [[ -z "${DHCP_PROXY_SUBNET}" ]]; then
        local prefix
        prefix=$(detect_prefix "${SERVER_IP}")
        [[ -n "${prefix}" ]] ||
          die "DHCP_MODE=proxy: SERVER_IP ${SERVER_IP} is not configured on any interface" \
              "(use host networking or set DHCP_PROXY_SUBNET)"
        DHCP_PROXY_SUBNET=$(network_of "${SERVER_IP}" "${prefix}")
      fi
      is_ipv4 "${DHCP_PROXY_SUBNET}" || die "DHCP_PROXY_SUBNET '${DHCP_PROXY_SUBNET}' is not a valid IPv4 address"
      ;;
    full)
      [[ -n "${DHCP_RANGE}" ]] ||
        die "DHCP_MODE=full requires DHCP_RANGE (e.g. 192.168.10.100,192.168.10.200,255.255.255.0,12h)"
      ;;
    *) die "DHCP_MODE must be 'none', 'proxy' or 'full'" ;;
  esac

  # thinRoot version of the bundled release images
  THINROOT_VERSION=$(cat "${PAYLOAD_DIR}/VERSION" 2>/dev/null || true)
  if [[ -z "${THINROOT_VERSION}" || "${THINROOT_VERSION}" == "unknown" ]]; then
    local img
    for img in "${PAYLOAD_DIR}"/thinroot-*.img; do
      [[ -f "${img}" ]] || continue
      THINROOT_VERSION=$(basename "${img}" | cut -d- -f2)
      break
    done
  fi
  : "${THINROOT_VERSION:=unknown}"
}

# user/group that dnsmasq and the nginx workers run as
setup_run_user() {
  RUN_USER=$(awk -F: -v id="${PUID}" '$3 == id { print $1; exit }' /etc/passwd)
  RUN_GROUP=$(awk -F: -v id="${PGID}" '$3 == id { print $1; exit }' /etc/group)
  if [[ -z "${RUN_GROUP}" ]]; then
    RUN_GROUP=thinroot
    echo "${RUN_GROUP}:x:${PGID}:" >>/etc/group
  fi
  if [[ -z "${RUN_USER}" ]]; then
    RUN_USER=thinroot
    echo "${RUN_USER}:x:${PUID}:${PGID}:thinRoot boot server:/nonexistent:/sbin/nologin" >>/etc/passwd
  fi
}

# label usable in iPXE scripts and PXELINUX configs
sanitize_label() {
  local label="${1//[^A-Za-z0-9_-]/-}"
  echo "${label,,}"
}

# cmdline helper: base arguments + THINROOT_CMDLINE_EXTRA
cmdline() {
  echo "$1${THINROOT_CMDLINE_EXTRA:+ ${THINROOT_CMDLINE_EXTRA}}"
}
