# syntax=docker/dockerfile:1
# check=skip=FromPlatformFlagConstDisallowed
#
# thinRoot boot server: serves thinRoot to network-booting clients via
# PXE/TFTP/HTTP and (optionally) DHCP/proxyDHCP. See docker/README.md.
#
# Build from the repository root, e.g.:
#
#   docker buildx build -f docker/Dockerfile \
#     --build-context payload=<directory with thinroot-*.img files> \
#     --build-arg THINROOT_VERSION=<YYYYMMDD> -t thinroot .
#
# Without "--build-context payload=..." the image contains no thinRoot
# release images (useful for testing only).

# thinRoot release images (thinroot-<version>-<product>*.img + .sha256).
# Replaced by the release workflow via `--build-context payload=<dir>`.
FROM scratch AS payload

# iPXE source, pinned to the commit of the release tag (v2.0.0)
FROM scratch AS ipxe-src
ARG IPXE_COMMIT=12798ec29aa8a64d8675c4378b99f5fe28447afb
ADD --keep-git-dir=false https://github.com/ipxe/ipxe.git#${IPXE_COMMIT} /

# iPXE with an embedded script. The bootloaders are x86 binaries for the
# clients, independent of the server architecture, so the bootloader stages
# always run as linux/amd64.
FROM --platform=linux/amd64 debian:trixie-slim AS ipxe
RUN apt-get update \
 && apt-get install -y --no-install-recommends binutils gcc libc6-dev liblzma-dev make perl \
 && rm -rf /var/lib/apt/lists/*
COPY --from=ipxe-src / /src
COPY docker/ipxe/ /ipxe-config/
RUN cp /ipxe-config/general.h /ipxe-config/console.h /src/src/config/local/ \
 && make -C /src/src -j"$(nproc)" NO_WERROR=1 EMBED=/ipxe-config/embed.ipxe \
      bin/undionly.kpxe bin/ipxe.pxe bin/ipxe.lkrn \
      bin-x86_64-efi/ipxe.efi bin-x86_64-efi/snponly.efi bin-i386-efi/ipxe.efi \
 && mkdir -p /out \
 && cp /src/src/bin/undionly.kpxe /src/src/bin/ipxe.pxe /src/src/bin/ipxe.lkrn /out/ \
 && cp /src/src/bin-x86_64-efi/ipxe.efi /src/src/bin-x86_64-efi/snponly.efi /out/ \
 && cp /src/src/bin-i386-efi/ipxe.efi /out/ipxe-i386.efi

# PXELINUX (syslinux) for legacy BIOS clients. lpxelinux.0 is the variant
# with HTTP support, so kernels can be loaded via http:// URLs.
FROM --platform=linux/amd64 debian:trixie-slim AS syslinux
RUN apt-get update \
 && apt-get install -y --no-install-recommends pxelinux syslinux-common \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /out \
 && cp /usr/lib/PXELINUX/lpxelinux.0 /usr/lib/syslinux/memdisk /out/ \
 && cp /usr/lib/syslinux/modules/bios/*.c32 /out/

# the boot server itself
FROM alpine:3.23

ARG THINROOT_VERSION=unknown

RUN apk add --no-cache bash dnsmasq iproute2 nginx tar tini xz

COPY --from=ipxe /out/ /usr/share/thinroot/bootloader/
COPY --from=syslinux /out/ /usr/share/thinroot/bootloader/
COPY tftpboot/thinroot/conf/ /usr/share/thinroot/default-data/conf/
COPY tftpboot/boot/pxe-banner.png /usr/share/thinroot/static/boot/pxe-banner.png
COPY docker/rootfs/ /
COPY --from=payload / /opt/thinroot/

RUN chmod 0755 /usr/local/bin/thinroot-entrypoint \
 && echo "${THINROOT_VERSION}" >/opt/thinroot/VERSION

# 67/udp + 4011/udp: DHCP/proxyDHCP (DHCP_MODE=proxy|full), 69/udp: TFTP, 80/tcp: HTTP
EXPOSE 67/udp 69/udp 80/tcp 4011/udp
VOLUME ["/data"]

HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -q -O /dev/null "http://127.0.0.1:${HTTP_PORT:-80}/healthz" || exit 1

LABEL org.opencontainers.image.title="thinRoot" \
      org.opencontainers.image.description="thinRoot network boot server (PXE/TFTP/HTTP/DHCP) including the thinRoot release images" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/jens-maus/thinRoot" \
      org.opencontainers.image.documentation="https://github.com/jens-maus/thinRoot/blob/master/docker/README.md" \
      org.opencontainers.image.version="${THINROOT_VERSION}"

ENTRYPOINT ["/sbin/tini", "-g", "--", "/usr/local/bin/thinroot-entrypoint"]
CMD ["run"]
