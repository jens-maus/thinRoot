# thinRoot boot server example data

This directory contains example data for a thinRoot boot server:

| Path | Content |
| --- | --- |
| `thinroot/conf/` | example thinRoot configuration (`thinroot.conf.network`, `thinroot.hosts`, group/host specific `thinroot.conf*` files, `qutselect.*`) |
| `thinroot/overlay/`, `thinroot/overlay_gen.sh` | example rootfs overlay and the script packing it into `overlay.pkg` |
| `thinroot/pkgs/` | example additional packages |
| `boot/pxe-banner.png` | background image of the iPXE boot menu |

The boot server itself (bootloaders, iPXE/PXELINUX menus, TFTP/HTTP/DHCP)
is provided by the thinRoot boot server container, which also uses
`thinroot/conf/` as example configuration on its first start. See
[docker/README.md](../docker/README.md).

## Boot servers without the container

To set up an own PXE/TFTP/HTTP server, the container can generate the
complete file tree (bootloaders, boot menus for your server address, thinRoot
images, configuration) without running it:

```sh
docker run --rm -e SERVER_IP=192.168.74.30 \
  -v "$PWD/data:/data" -v "$PWD/tftpboot:/export" \
  ghcr.io/jens-maus/thinroot:latest export
```

Serve the resulting `tftpboot/` directory via TFTP and HTTP and configure
your DHCP server as described in [docker/README.md](../docker/README.md).
