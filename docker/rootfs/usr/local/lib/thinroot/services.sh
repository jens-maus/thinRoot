#!/bin/bash
# shellcheck shell=bash
#
# thinRoot boot server: dnsmasq (TFTP, DHCP/proxyDHCP) and nginx (HTTP)
# configuration
#

gen_dnsmasq() {
  local out="${RUN_DIR}/dnsmasq.conf"
  {
    cat <<EOF
# thinRoot boot server - generated on container start, do not edit.
# Additional settings can be put into ${DATA_DIR}/dnsmasq.d/*.conf

# no DNS server
port=0
log-facility=-
user=${RUN_USER}
group=${RUN_GROUP}

# TFTP
enable-tftp
tftp-root=${TFTP_ROOT}
EOF
    is_true "${TFTP_SINGLE_PORT}" && echo "tftp-single-port"
    [[ -n "${INTERFACE}" ]] && echo "interface=${INTERFACE}"
    [[ "${LOG_LEVEL}" == "debug" ]] && echo "log-dhcp"

    if [[ "${DHCP_MODE}" != "none" ]]; then
      cat <<EOF

# client detection
dhcp-userclass=set:ipxe,iPXE
dhcp-match=set:ipxe,175
dhcp-match=set:bios,option:client-arch,0
dhcp-match=set:efi32,option:client-arch,6
dhcp-match=set:efi64,option:client-arch,7
dhcp-match=set:efi64,option:client-arch,9
EOF
    fi

    case "${DHCP_MODE}" in
      proxy)
        # iPXE clients get boot/net.ipxe, all others the configured bootloader
        cat <<EOF

# proxyDHCP: only PXE boot information, addresses come from the existing DHCP server
dhcp-range=${DHCP_PROXY_SUBNET},proxy
pxe-service=tag:!ipxe,x86PC,"thinRoot",${LEGACY_FILE}
pxe-service=tag:!ipxe,BC_EFI,"thinRoot",${UEFI64_FILE}
pxe-service=tag:!ipxe,X86-64_EFI,"thinRoot",${UEFI64_FILE}
pxe-service=tag:!ipxe,IA32_EFI,"thinRoot",${UEFI32_FILE}
pxe-service=tag:ipxe,x86PC,"thinRoot",boot/net.ipxe
pxe-service=tag:ipxe,BC_EFI,"thinRoot",boot/net.ipxe
pxe-service=tag:ipxe,X86-64_EFI,"thinRoot",boot/net.ipxe
pxe-service=tag:ipxe,IA32_EFI,"thinRoot",boot/net.ipxe
EOF
        ;;
      full)
        echo
        echo "# DHCP server"
        echo "dhcp-range=${DHCP_RANGE}"
        echo "dhcp-leasefile=${DATA_DIR}/dnsmasq.leases"
        [[ -n "${DHCP_ROUTER}" ]] && echo "dhcp-option=option:router,${DHCP_ROUTER}"
        [[ -n "${DHCP_DNS}" ]] && echo "dhcp-option=option:dns-server,${DHCP_DNS}"
        [[ -n "${DHCP_DOMAIN}" ]] && echo "dhcp-option=option:domain-name,${DHCP_DOMAIN}"
        is_true "${DHCP_AUTHORITATIVE}" && echo "dhcp-authoritative"
        cat <<EOF
dhcp-boot=tag:ipxe,boot/net.ipxe,,${SERVER_IP}
dhcp-boot=tag:!ipxe,tag:bios,${LEGACY_FILE},,${SERVER_IP}
dhcp-boot=tag:!ipxe,tag:efi64,${UEFI64_FILE},,${SERVER_IP}
dhcp-boot=tag:!ipxe,tag:efi32,${UEFI32_FILE},,${SERVER_IP}
EOF
        ;;
    esac

    if [[ -d "${DATA_DIR}/dnsmasq.d" ]]; then
      echo
      echo "conf-dir=${DATA_DIR}/dnsmasq.d,*.conf"
    fi
  } >"${out}"

  if [[ "${DHCP_MODE}" == "full" ]]; then
    touch "${DATA_DIR}/dnsmasq.leases"
    chown "${PUID}:${PGID}" "${DATA_DIR}/dnsmasq.leases"
  fi
}

gen_nginx() {
  local out="${RUN_DIR}/nginx.conf" access_log=off autoindex=off
  is_true "${HTTP_ACCESS_LOG}" && access_log="/dev/stdout thinroot"
  is_true "${HTTP_AUTOINDEX}" && autoindex=on
  mkdir -p "${RUN_DIR}/nginx"
  chown "${PUID}:${PGID}" "${RUN_DIR}/nginx"

  {
    cat <<EOF
# thinRoot boot server - generated on container start, do not edit.
daemon off;
user ${RUN_USER} ${RUN_GROUP};
worker_processes auto;
pid ${RUN_DIR}/nginx.pid;
error_log stderr warn;

events {
  worker_connections 1024;
}

http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  log_format thinroot '[http] \$remote_addr "\$request" \$status \$body_bytes_sent';
  access_log ${access_log};

  client_body_temp_path ${RUN_DIR}/nginx/client_body;
  proxy_temp_path ${RUN_DIR}/nginx/proxy;
  fastcgi_temp_path ${RUN_DIR}/nginx/fastcgi;
  uwsgi_temp_path ${RUN_DIR}/nginx/uwsgi;
  scgi_temp_path ${RUN_DIR}/nginx/scgi;

  sendfile on;
  tcp_nopush on;
  keepalive_timeout 65;
  server_tokens off;

  server {
    listen ${HTTP_PORT} default_server;
EOF
    if [[ -f /proc/net/if_inet6 ]]; then
      echo "    listen [::]:${HTTP_PORT} default_server;"
    fi
    cat <<EOF
    root ${TFTP_ROOT};
    autoindex ${autoindex};
    # clients probe many optional files (mac-*.ipxe, group/host configs)
    log_not_found off;

    location = /healthz {
      access_log off;
      default_type text/plain;
      return 200 "ok\n";
    }

    location ~ \.(ipxe|cfg|theme)\$ {
      default_type text/plain;
      add_header Cache-Control "no-cache";
    }

    location /thinroot/conf/ {
      default_type text/plain;
      add_header Cache-Control "no-cache";
    }
  }
}
EOF
  } >"${out}"
}
