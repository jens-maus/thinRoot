# thinRoot boot server container

The `ghcr.io/jens-maus/thinroot` container image provides everything thinRoot
clients need to boot from the network, together with the thinRoot release
images:

* **TFTP** (dnsmasq): bootloaders, iPXE/PXELINUX menus and the Raspberry Pi
  kernel/initrd images
* **HTTP** (nginx): the thinRoot images and the client configuration
  (`conf/`, `overlay.pkg*`, `pkgs/`)
* **DHCP** (dnsmasq, optional): either as proxyDHCP next to an existing DHCP
  server or as a full DHCP server
* **Bootloaders**: iPXE (built from source, BIOS + UEFI) and PXELINUX
  (syslinux) for legacy BIOS clients

Updating thinRoot is a matter of pulling a new container image; the
configuration lives in a separate `/data` volume.

## Image tags

| Tag | Content |
| --- | --- |
| `latest` | latest release, all platforms (generic-x86_64, rpi3, rpi4, rpi5) |
| `latest-x86_64` | latest release, generic-x86_64 only (much smaller) |
| `YYYYMMDD`, `YYYYMMDD-x86_64` | a specific thinRoot release |
| `YYYYMMDD-<commit>`, `YYYYMMDD-<commit>-x86_64` | a specific build of a release |

The images are available for `linux/amd64`, `linux/arm64` and `linux/arm/v7`
servers. The architecture of the server does not matter for the clients.

## Boot flow

```text
 x86_64 BIOS:  PXE ROM ─DHCP─> pxelinux.0 (or undionly.kpxe) ─TFTP─> menu ─HTTP─> thinroot/thinroot.img
 x86_64 UEFI:  PXE ROM ─DHCP─> snponly.efi (iPXE) ─TFTP─> boot/net.ipxe ─HTTP─> thinroot/thinroot.img
 Raspberry Pi: U-Boot (SD card) ─DHCP+TFTP─> thinroot/thinroot-rpiX-kernel.img + thinroot-rpiX.img
 thinRoot:     S42LoadNetFiles ─HTTP─> thinroot/conf/*, thinroot/overlay.pkg*
```

All iPXE binaries contain an embedded script that continues with
`boot/net.ipxe` from the server that announced them (proxyDHCP server or DHCP
`next-server`). No server address is compiled into the binaries.

## Quick start

1. Create a directory for the configuration and a `docker-compose.yml` (see
   [docker-compose.yml](docker-compose.yml)). Replace `192.168.74.30` with
   the IPv4 address of your Docker host: with `DHCP_MODE=proxy` the container
   refuses to start if the host does not own `SERVER_IP`.

   ```yaml
   services:
     thinroot:
       image: ghcr.io/jens-maus/thinroot:latest
       container_name: thinroot
       restart: unless-stopped
       network_mode: host
       cap_add:
         - NET_ADMIN
       environment:
         SERVER_IP: 192.168.74.30
         DHCP_MODE: proxy
       volumes:
         - ./data:/data
   ```

2. Start it with `docker compose up -d`. On the first start an example
   configuration is created in `./data/conf`.
3. Adapt `./data/conf/thinroot.conf.network`, `thinroot.hosts`, etc. to your
   environment (see the thinRoot documentation). Changes in `conf/` are live,
   no restart is needed.
4. Boot a client from the network.

Updating: `docker compose pull && docker compose up -d`.

## DHCP modes

| `DHCP_MODE` | Use case | Requirements |
| --- | --- | --- |
| `none` (default) | an existing DHCP server is configured to announce the boot server | – |
| `proxy` | an existing DHCP server (e.g. a home router) that cannot be configured; the container only adds the PXE boot information (proxyDHCP) | host networking, `NET_ADMIN` |
| `full` | isolated network without DHCP server; the container hands out addresses itself | host networking, `NET_ADMIN`, `DHCP_RANGE` |

Never run `DHCP_MODE=full` in a network that already has a DHCP server.

### Configuring an existing DHCP server (`DHCP_MODE=none`)

The DHCP server has to announce the container as `next-server` (option 66 /
`siaddr`) and a boot file depending on the client architecture
(option 93):

| Client | Boot file |
| --- | --- |
| BIOS (arch 0) | `pxelinux.0` (or `undionly.kpxe` for iPXE) |
| UEFI x64 (arch 7, 9) | `snponly.efi` (or `ipxe.efi`) |
| UEFI ia32 (arch 6) | `ipxe-i386.efi` |

ISC dhcpd:

```text
option arch code 93 = unsigned integer 16;
next-server 192.168.74.30;
if option arch = 00:07 or option arch = 00:09 {
  filename "snponly.efi";
} elsif option arch = 00:06 {
  filename "ipxe-i386.efi";
} else {
  filename "pxelinux.0";
}
```

dnsmasq / Pi-hole:

```text
dhcp-match=set:efi32,option:client-arch,6
dhcp-match=set:efi64,option:client-arch,7
dhcp-match=set:efi64,option:client-arch,9
dhcp-boot=tag:efi32,ipxe-i386.efi,,192.168.74.30
dhcp-boot=tag:efi64,snponly.efi,,192.168.74.30
dhcp-boot=tag:!efi32,tag:!efi64,pxelinux.0,,192.168.74.30
```

OPNsense/pfSense (DHCP server, *Network booting*): next server
`192.168.74.30`, default BIOS file name `pxelinux.0`, UEFI 64 bit file name
`snponly.efi`.

The file names of the former `tftpboot/` example setup (`ipxe.x86_64.efi`,
`ipxe.i386.efi`, `pxeboot.0`, `Boot\x64\wdsmgfw.efi`) are available as aliases.

## Network setup

**Host networking** (`network_mode: host`) is recommended. It is required for
`DHCP_MODE=proxy|full` and avoids any issues with TFTP and NAT.

Without host networking (only with `DHCP_MODE=none`), publish the ports and
tell the container under which address and port it is reachable:

```yaml
    ports:
      - "69:69/udp"
      - "8080:80"
    environment:
      SERVER_IP: 192.168.74.30
      BOOT_URL: http://192.168.74.30:8080/
      TFTP_SINGLE_PORT: "true"
```

## Settings

| Variable | Default | Description |
| --- | --- | --- |
| `SERVER_IP` | auto-detected | IPv4 address of the server as seen by the clients. Set it explicitly unless host networking is used. |
| `HTTP_PORT` | `80` | HTTP port inside the container |
| `BOOT_URL` | `http://<SERVER_IP>[:<HTTP_PORT>]/` | base URL the clients use, e.g. with a reverse proxy or published port |
| `DHCP_MODE` | `none` | `none`, `proxy` or `full` (see above) |
| `DHCP_PROXY_SUBNET` | network of `SERVER_IP` | network address for `DHCP_MODE=proxy` |
| `DHCP_RANGE` | – | `DHCP_MODE=full`: dnsmasq `dhcp-range`, e.g. `192.168.10.100,192.168.10.200,255.255.255.0,12h` |
| `DHCP_ROUTER`, `DHCP_DNS`, `DHCP_DOMAIN` | – | `DHCP_MODE=full`: default gateway, DNS server(s), domain name |
| `DHCP_AUTHORITATIVE` | `false` | `DHCP_MODE=full`: act as authoritative DHCP server |
| `INTERFACE` | all | restrict DHCP and TFTP to one network interface |
| `TFTP_SINGLE_PORT` | `false` | use only port 69 for TFTP (needed behind NAT/port publishing) |
| `LEGACY_BOOTLOADER` | `pxelinux` | bootloader for BIOS clients: `pxelinux` or `ipxe` (`undionly.kpxe`) |
| `UEFI_BOOTLOADER` | `snponly` | bootloader for UEFI clients: `snponly` (`snponly.efi`, uses the firmware network driver) or `ipxe` (`ipxe.efi`, own drivers) |
| `MENU_DEFAULT` | `thinroot` | default boot menu entry, e.g. `thinroot-debug`, `thinroot-beta`, `local` |
| `MENU_TIMEOUT` | `4` | seconds to press SPACE (iPXE) or a key (PXELINUX) for the boot menu |
| `MENU_SHOW` | `false` | always show the boot menu, boot the default entry after `MENU_TIMEOUT` seconds (`0` = wait) |
| `ADMIN_PASSWORD` | – | enables the password protected iPXE shell entry (letters, digits, `._+-`) |
| `THINROOT_CMDLINE` | see `common.sh` | kernel command line of the thinRoot entries |
| `THINROOT_CMDLINE_DEBUG` | see `common.sh` | kernel command line of the debug entries |
| `THINROOT_CMDLINE_EXTRA` | – | additional kernel parameters for all thinRoot entries |
| `PUID`, `PGID` | `1000` | user/group the TFTP and HTTP server run as; files in `/data` must be readable for them |
| `HTTP_ACCESS_LOG` | `true` | log HTTP requests |
| `HTTP_AUTOINDEX` | `false` | enable directory listings |
| `LOG_LEVEL` | `info` | `debug` additionally logs DHCP details |

## The `/data` volume

```text
/data/
├── conf/              thinRoot configuration, served as /thinroot/conf/ (live)
├── pkgs/              additional packages, served as /thinroot/pkgs/ (live)
├── overlay/           packed into /thinroot/overlay.pkg on start
├── overlay<suffix>/   packed into /thinroot/overlay.pkg<suffix>, e.g. overlay.group-A/
├── overlay.pkg*       prebuilt overlay packages, served as they are
├── images/            own images in /thinroot/, e.g. thinroot-beta.img
├── extras/            served at the top level, e.g. memtest/, clonezilla/, sysrescue/
├── boot/              own or additional iPXE scripts in /boot/
├── pxelinux.cfg/      own or additional PXELINUX configs in /pxelinux.cfg/
├── dnsmasq.d/         additional dnsmasq settings (*.conf)
└── dnsmasq.leases     DHCP leases (DHCP_MODE=full)
```

Restart the container after adding or removing files outside of `conf/` and
`pkgs/`, the boot menus and overlay packages are generated on start.

* **Own images**: `images/thinroot-beta.img` (or any other `*.img` for
  x86_64) gets its own entries in the iPXE and PXELINUX menus. An image with
  the name of a bundled one (e.g. `thinroot.img`, `thinroot-rpi4.img`)
  replaces it.
* **Tools**: boot menu entries are added when `extras/memtest/memtest64.bin`
  (BIOS) or `memtest64.efi` (UEFI), `extras/clonezilla/live/{vmlinuz,initrd.img,filesystem.squashfs}`
  or `extras/sysrescue/sysresccd/boot/x86_64/{vmlinuz,sysresccd.img}` exist.
* **Per client settings**: `boot/mac-<mac without colons>.ipxe` is run
  before the iPXE menu, e.g. to change the default entry:

  ```text
  #!ipxe
  set menu-default local
  chain ${boot-menu}
  ```

  For PXELINUX, create `pxelinux.cfg/01-<mac with dashes>`:

  ```text
  INCLUDE pxelinux.cfg/default
  ONTIMEOUT local
  ```

The files are served without authentication to everyone who can reach the
server. Do not put anything into `/data` that must stay secret from the
network (overlays with password hashes or SSH keys are readable by every
client, as with any TFTP/HTTP boot server).

## Served files

```text
/                      bootloaders: pxelinux.0, *.c32, undionly.kpxe, ipxe.pxe, ipxe.lkrn, ipxe.efi, snponly.efi, ipxe-i386.efi
/boot/                 net.ipxe, net.cfg, menu-main.ipxe, net.theme (generated)
/pxelinux.cfg/default  PXELINUX menu (generated)
/thinroot/             thinroot.img, thinroot-<version>-<product>*.img, thinroot-rpiX[-kernel].img,
                       conf/, pkgs/, overlay.pkg*
```

## Raspberry Pi

Flash the `*-sdcard.img` of the release onto an SD card and set in
`bootEnv.txt` of its boot partition:

```text
bootserver=192.168.74.30
kernel_img=thinroot/thinroot-rpi4-kernel.img
initrd=thinroot/thinroot-rpi4.img
extraargs=BASE_PATH=http://192.168.74.30/thinroot
```

The version independent file names stay valid when the container is updated.

## Building the image yourself

```sh
mkdir payload
# put the thinroot-<version>-<product>*.img files of a release into payload/
docker buildx build -f docker/Dockerfile \
  --build-context payload=payload \
  --build-arg THINROOT_VERSION=<version> \
  -t thinroot:local --load .
docker/tests/smoke-test.sh thinroot:local <version>
```

`docker run --rm -e SERVER_IP=... thinroot:local check` only generates and
validates the configuration.

## Using the files without running the container

For an own PXE/TFTP/HTTP server, `export` writes the complete tree that the
container would serve (bootloaders, generated boot menus for `SERVER_IP`,
thinRoot images, configuration from `/data`) into the empty directory
mounted at `/export`:

```sh
mkdir thinroot-export
docker run --rm -e SERVER_IP=192.168.74.30 \
  -v "$PWD/data:/data" -v "$PWD/thinroot-export:/export" \
  ghcr.io/jens-maus/thinroot:latest export
```

The target directory has to be empty, so that no stale or modified files get
mixed with the generated tree. Replace `192.168.74.30` with the address of
your boot server.

## Troubleshooting

* Run with `LOG_LEVEL=debug` to see DHCP details and check the container log
  for TFTP (`dnsmasq-tftp`) and HTTP (`[http]`) requests.
* The generated files can be inspected with
  `docker exec thinroot cat /srv/tftpboot/boot/menu-main.ipxe` or
  `curl http://<server>/pxelinux.cfg/default`.
* proxyDHCP and the full DHCP server only work with host networking and the
  `NET_ADMIN` capability.
* Some firewalls on the Docker host block DHCP/TFTP (UDP 67, 69, 4011) and
  HTTP: open these ports for the client network.
