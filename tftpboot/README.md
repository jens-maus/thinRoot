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
images, configuration) into a new, empty directory without running it:

```sh
mkdir thinroot-export
docker run --rm -e SERVER_IP=192.168.74.30 \
  -v "$PWD/data:/data" -v "$PWD/thinroot-export:/export" \
  ghcr.io/jens-maus/thinroot:latest export
```

The target directory has to be empty, so that no stale or modified files get
mixed with the generated tree. Replace `192.168.74.30` with the address of
your boot server.

Serve the resulting `thinroot-export/` directory via TFTP and HTTP and configure
your DHCP server as described in [docker/README.md](../docker/README.md).
