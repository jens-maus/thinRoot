#!/bin/bash
#
# Smoke test for the thinRoot boot server image.
#
# Usage: docker/tests/smoke-test.sh <image> [<thinroot version>]
#
# Starts the container in bridge mode (TFTP single port mode behind NAT) and
# checks the generated configuration, HTTP and TFTP. Needs docker and curl
# (with TFTP support).
#

set -euo pipefail

IMAGE=${1:?usage: $0 <image> [<thinroot version>]}
VERSION=${2:-}
NAME="thinroot-smoke-$$"
HTTP_PORT=18080
TFTP_PORT=16969
SERVER_IP=192.0.2.10
DATA=$(mktemp -d)
FAILED=0

cleanup() {
  if [[ ${FAILED} -ne 0 ]]; then
    docker logs "${NAME}" 2>&1 | tail -n 50 || true
  fi
  docker rm -f "${NAME}" >/dev/null 2>&1 || true
  docker run --rm -v "${DATA}:/data" --entrypoint /bin/sh "${IMAGE}" -c 'rm -rf /data/*' >/dev/null 2>&1 || true
  rm -rf "${DATA}"
}
trap cleanup EXIT

ok() { echo "ok   - $*"; }
fail() {
  echo "FAIL - $*"
  FAILED=1
}

# check <description> <command...>
check() {
  local desc=$1
  shift
  if "$@" >/dev/null 2>&1; then ok "${desc}"; else fail "${desc}"; fi
}

http_get() { curl -fsS "http://127.0.0.1:${HTTP_PORT}/$1"; }
http_contains() { http_get "$1" | grep -qF -- "$2"; }
tftp_get() { curl -fsS -o /dev/null "tftp://127.0.0.1:${TFTP_PORT}/$1"; }

start_container() {
  docker rm -f "${NAME}" >/dev/null 2>&1 || true
  docker run -d --name "${NAME}" \
    -p "127.0.0.1:${HTTP_PORT}:80" -p "127.0.0.1:${TFTP_PORT}:69/udp" \
    -e SERVER_IP="${SERVER_IP}" -e TFTP_SINGLE_PORT=true \
    -e PUID="$(id -u)" -e PGID="$(id -g)" "$@" \
    -v "${DATA}:/data" "${IMAGE}" >/dev/null
  local _
  for _ in $(seq 1 30); do
    if curl -fsS -o /dev/null "http://127.0.0.1:${HTTP_PORT}/healthz" 2>/dev/null; then
      return 0
    fi
    sleep 1
  done
  fail "container did not become ready"
  exit 1
}

echo "# configuration checks"
check "check: DHCP_MODE=none" docker run --rm -e SERVER_IP="${SERVER_IP}" "${IMAGE}" check
check "check: DHCP_MODE=proxy" docker run --rm -e SERVER_IP="${SERVER_IP}" -e DHCP_MODE=proxy \
  -e DHCP_PROXY_SUBNET=192.0.2.0 "${IMAGE}" check
check "check: DHCP_MODE=full" docker run --rm -e SERVER_IP="${SERVER_IP}" -e DHCP_MODE=full \
  -e DHCP_RANGE=192.0.2.100,192.0.2.200,255.255.255.0,12h -e DHCP_ROUTER=192.0.2.1 "${IMAGE}" check
check "check: LEGACY_BOOTLOADER=ipxe, UEFI_BOOTLOADER=ipxe" docker run --rm -e SERVER_IP="${SERVER_IP}" \
  -e LEGACY_BOOTLOADER=ipxe -e UEFI_BOOTLOADER=ipxe "${IMAGE}" check
check "check: invalid DHCP_MODE is rejected" \
  bash -c "! docker run --rm -e SERVER_IP=${SERVER_IP} -e DHCP_MODE=foo ${IMAGE} check"
check "check: DHCP_MODE=full without DHCP_RANGE is rejected" \
  bash -c "! docker run --rm -e SERVER_IP=${SERVER_IP} -e DHCP_MODE=full ${IMAGE} check"

echo "# first start"
start_container
check "example configuration created" test -f "${DATA}/conf/thinroot.conf.network"
check "HTTP: healthz" http_contains healthz ok
check "HTTP: boot/net.ipxe" http_contains boot/net.ipxe "chain --autofree net.cfg"
check "HTTP: boot/net.cfg contains boot URL" http_contains boot/net.cfg "set boot-url http://${SERVER_IP}/"
check "HTTP: boot/menu-main.ipxe" http_contains boot/menu-main.ipxe ":thinroot"
check "HTTP: pxelinux.cfg/default" http_contains pxelinux.cfg/default \
  "KERNEL http://${SERVER_IP}/thinroot/thinroot.img"
check "HTTP: thinroot/conf/thinroot.conf.network" http_get thinroot/conf/thinroot.conf.network
check "HTTP: thinroot/thinroot.img" http_get thinroot/thinroot.img
if [[ -n "${VERSION}" ]]; then
  check "HTTP: version ${VERSION} in boot menu" http_contains boot/menu-main.ipxe "thinRoot ${VERSION}"
fi
for f in undionly.kpxe ipxe.pxe ipxe.lkrn ipxe.efi snponly.efi ipxe-i386.efi \
         pxelinux.0 lpxelinux.0 ldlinux.c32 menu.c32 libutil.c32 \
         pxelinux.cfg/default boot/net.ipxe thinroot/thinroot.img; do
  check "TFTP: ${f}" tftp_get "${f}"
done

echo "# overlays, own images and extras"
mkdir -p "${DATA}/overlay/etc" "${DATA}/extras/memtest"
echo "hello" >"${DATA}/overlay/etc/motd"
echo "beta" >"${DATA}/images/thinroot-beta.img"
echo "memtest" >"${DATA}/extras/memtest/memtest64.bin"
start_container -e MENU_DEFAULT=thinroot-beta -e ADMIN_PASSWORD=secret
check "HTTP: thinroot/overlay.pkg contains etc/motd" \
  bash -c "curl -fsS http://127.0.0.1:${HTTP_PORT}/thinroot/overlay.pkg | tar -tJf - | grep -qx './etc/motd'"
check "HTTP: thinroot/thinroot-beta.img" http_contains thinroot/thinroot-beta.img beta
check "iPXE menu: beta entry is default" http_contains boot/menu-main.ipxe "set menu-default thinroot-beta"
check "iPXE menu: memtest entry" http_contains boot/menu-main.ipxe ":memtest"
check "iPXE menu: admin shell" http_contains boot/menu-main.ipxe ":shell"
check "PXELINUX menu: memtest entry" http_contains pxelinux.cfg/default "memtest/memtest64.bin"

if [[ ${FAILED} -ne 0 ]]; then
  echo "smoke test FAILED"
  exit 1
fi
echo "smoke test passed"
