<img src="buildroot-external/patches/psplash/thinroot/logo.png" width="250px" align="center">

[![Current Release](https://img.shields.io/github/release/jens-maus/thinRoot.svg)](https://github.com/jens-maus/thinRoot/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/jens-maus/thinRoot/latest/total.svg)](https://github.com/jens-maus/thinRoot/releases/latest)
[![Contributors](https://img.shields.io/github/contributors/jens-maus/thinRoot.svg)](https://github.com/jens-maus/thinRoot/graphs/contributors)
[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/jens-maus/thinRoot.svg)](https://github.com/jens-maus/thinRoot/issues)
[![Percentage of issues still open](http://isitmaintained.com/badge/open/jens-maus/thinRoot.svg)](https://github.com/jens-maus/thinRoot/issues)
[![Commits since last release](https://img.shields.io/github/commits-since/jens-maus/thinRoot/latest.svg)](https://github.com/jens-maus/thinRoot/releases/latest)
[![License](https://img.shields.io/github/license/jens-maus/thinRoot.svg)](https://github.com/jens-maus/thinRoot/blob/master/LICENSE)
[![Donate](https://img.shields.io/badge/donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RAQSDY9YNZVCL)
[![GitHub stars](https://img.shields.io/github/stars/jens-maus/thinRoot.svg?style=social&label=Star)](https://github.com/jens-maus/thinRoot/stargazers/)

_thinRoot_ is a buildroot (https://buildroot.org/) powered operating system environment to create lightweight user-defined kiosk systems or ThinClients for generic x86_64 hardware (e.g. intelNUC, standard PCs, Laptops, etc.) or single-board computer (SBC) driven embedded systems (RaspberryPi, ASUS Tinkerboard, etc.) to smoothly connect to server-based desktop environments (Linux/Windows Terminalserver, VDIs, etc.) via included ThinLinc, RDP (xfreerdp), VNC, SPICE, etc. clients or to create simply web-kiosk systems displaying a single fullscreen webpage upon bootup.

## :cookie: Features
* allows to be setup as a lightweight and generic ThinClient system which after bootup providing a simple connection GUI (using [qutselect](https://github.com/hzdr/qutselect)) with options to connect via [ThinLinc](http://www.cendio.se/), RDP (via [freerdp](https://github.com/FreeRDP/FreeRDP)), VNC or [SPICE](https://www.spice-space.org/) to Linux- or Windows-based desktop systems (Terminalserver, VDI, etc.) including potential USB device redirection/forwarding.
* allows to be setup to start only a fullscreen webbrowser (via [WebKit/MiniBrowser](https://github.com/WebKit/WebKit/tree/main/Tools/MiniBrowser)) for simple fullscreen webkiosk use-cases.
* direct support for SPICE-based connections to SPICE-enabled VDI systems hosted via [ProxmoxVE](https://www.proxmox.com/en/) including cluster proxied connection support.
* boots and operates completly in a full-fledged RAM disk with no mandatory local disk storage requirements.
* allows to be booted solely using existing PXE+TFTP/HTTP+DHCP-based netboot environments or to directly install the thinRoot images onto a small local boot disk.
* allows to use a TFTP/HTTP-connected bootserver: fetches environment files from a bootserver which then can be used to define alternative system bootup procedures (based on the hostname/MAC of the client system) by simply changing these environment files on the TFTP/HTTP bootserver.
* highly optimized for a small footprint: compressed kernel and system for fast network-based bootup use-cases.
* easily adaptable to other potential use cases apart from simple web-kiosk or ThinClient environment uses.
* can be easily enhanced to support more x86/ARM-based hardware.

## :computer: Requirements

1. A supported x86_64/ARM-based hardware. Well working and tested hardware:
   * All generic x86_64-based hardware (e.g. Intel NUC, modern Laptops, etc.) which comes with directly supported PXE boot capabilities in the BIOS.
   * All ARM-based single board computer (SBC) systems supported by the [U-Boot](https://www.denx.de/project/u-boot/) bootloader which is used to provide a common way to boot the kernel and initrd via network. This includes:
     * [RaspberryPi5 Model B](https://www.raspberrypi.com/products/raspberry-pi-5/), [RaspberryPi Compute Module 5](https://www.raspberrypi.com/products/compute-module-5), [RaspberryPi 500](https://www.raspberrypi.com/products/raspberry-pi-500/)
     * [RaspberryPi4 Model B](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/), [RaspberryPi Compute Module 4](https://www.raspberrypi.com/products/compute-module-4), [RaspberryPi 400](https://www.raspberrypi.com/products/raspberry-pi-400-unit/)
     * [RaspberryPi3 Model B+](https://www.raspberrypi.com/products/raspberry-pi-3-model-b-plus/), [RaspberryPi3 Model B](https://www.raspberrypi.com/products/raspberry-pi-3-model-b/), [RaspberryPi3 Model A+](https://www.raspberrypi.com/products/raspberry-pi-3-model-a-plus/), [RaspberryPi Compute Module 3](https://www.raspberrypi.com/products/compute-module-3-plus/), [RaspberryPi Zero 2 W](https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/)
     * [TinkerBoard S](https://www.asus.com/de/networking-iot-servers/aiot-industrial-solutions/all-series/tinker-board-s/), [TinkerBoard](https://www.asus.com/de/networking-iot-servers/aiot-industrial-solutions/all-series/tinker-board/)
2. An already working PXE+TFTP/HTTP+DHCP bootserver environment where the thinRoot images and its environment files can be installed and directly accessed upon bootup via TFTP/HTTP sideloading.
3. In case of a ThinClient use-case: A network-based desktop environment (e.g. Windows Terminalserver, VDI system, etc.) to connect to via ThinLinc, RDP, VNC or SPICE protocol.
4. In case of a web-kisok use-case: A web page that can be configured using a bootserver-definable environment file so that thinRoot automatically starts as a lightweight web-kiosk.

## :cloud: Quick-Installation
The installation of thinRoot is quite straight forward as it is delivered as fully network bootable system images which boot directly into a RAMdisk using images hosted by a an already existing PXE+TFTP/HTTP+DHCP environment:

1. [Download latest release](https://github.com/jens-maus/thinRoot/releases) zip archive for the hardware platform you are interesed in:
   - *generic-x86_64*
     1. Put the unarchived `*.img` file into your tftpboot PXE environment (e.g. under `/tftpboot/thinroot`).
   - *RaspberryPi, Tinkerboard*:
     1. Put the unarchived `*-[platform]-kernel.img` and `*-[platform].img` file into your existing tftpboot PXE environment where `[platform]` corresponds to your chosen hardware image.
     2. Use an imaging tool (e.g. [Etcher](https://github.com/balena-io/etcher) to flash the included `*-[platform]-sdcard.img` files to a fresh microSD card or USB thumb drive.
     3. Modify the `/boot/bootEnv.txt` file in the FAT32 boot partition to match your TFTP/HTTP bootserver setup.
2. Make sure your PXE+TFTP/HTTP+DHCP/bootserver provides the image files also via HTTP (e.g. using a nginx proxy against `/tftpboot`).
3. (`generic-x86_64`): Modify your PXE+TFTP/HTTP+DHCP/bootserver environment to load the corresponding `*.img` via HTTP and with the following APPEND line
   - *iPXE/UEFI boot environment*:
     ```cfg
     set root-path http://192.168.74.30/thinroot/
     kernel ${root-path}thinroot.img
     imgargs thinroot.img BOOT_IMAGE=${root-path}/thinroot.img console=tty2 noswap noinitrd consoleblank=120 init_on_alloc=1 init_on_free=0 slab_nomerge net.ifnames=0 intel_iommu=igfx_off quiet loglevel=0
     ```
   - *Syslinux/Legacy boot environment*:
     ```cfg
     LABEL      thinroot
     MENU LABEL ^thinRoot (stable)
     KERNEL     http://192.168.74.30/thinroot/thinroot.img
     APPEND     console=tty2 noswap noinitrd consoleblank=120 init_on_alloc=1 init_on_free=0 slab_nomerge net.ifnames=0 intel_iommu=igfx_off quiet loglevel=0
     ```
4. (`rpi*, tinkerboard*`): Modify the `/boot/bootEnv.txt` file on the microSD card/USB thumb drive to match your PXE+TFTP/HTTP+DHCP environment:
   ```
   bootserver=192.168.74.30
   kernel_img=thinroot/thinroot-tinkerboard-kernel.img
   initrd=thinroot/thinroot-tinkerboard.img
   extraargs=BASE_PATH=http://192.168.74.30/thinroot
   ```
   Make sure to remove comments (`#`) from lines which are required and modify the pathes to match your  PXE+TFTP/HTTP+DHCP environment. For example, it might also simply be enough to just enable the `extraargs=...` line if you want the image on the microSD card itself to be booted. However, if you want to fetch the kernel image and initrd from the `bootserver` make sure to uncomment these lines as well.

## :yum: How to contribute
As the thinRoot project is an open source based project everyone is invited to contribute to this project. So, if you are a talented developer and want to contribute to the success of thinRoot feel free to send over pull requests or report issues / enhancement requests. Please note, however, the licensing and contributing implications and accept that - in short - anything you contribute to this repository/project (especially source code) will be (re)licensed under the Apache 2.0 license (see [CONTRIBUTING.md](CONTRIBUTING.md)). In addition, please understand that we will only accept contributions (either source code or issues in the issue tracker) if these comply to our [CODE OF CONDUCT](CODE_OF_CONDUCT.md).

### :moneybag: Donations [![Donate](https://img.shields.io/badge/donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RAQSDY9YNZVCL)
Even for those that don't have the technical knowhow to help developing on thinRoot there are ways to support our development. Please consider sending us a donation to not only help us to compensate for expenses regarding thinRoot, but also to keep our general development motivation on a high level. So if you want to donate some money please feel free to send us money via [PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RAQSDY9YNZVCL). And if you are running a business which might integrate thinRoot in one of your products please contact us for a regular donation plan which could not only show that you do care about open source development, but also could secure your product by ensuring that development on thinRoot continues in future.

### :construction: Development
Building your own thinRoot image is a very straight forward process using this build environment – given that you have sufficient Linux/Unix knowledge and you know what you are actually doing. But if you know what you are doing and which host tools are required to actually be able to run a thinRoot build, it should be as simple as:

```sh
$ git clone https://github.com/jens-maus/thinRoot
$ cd thinRoot
$ make PRODUCT=generic-x86_64 release
[wait up to 1h]
$ cp release/thinroot-YYYYMMDD-generic-x86_64.img /tftpboot/thinroot/
```

## :scroll: License
The thinRoot build environment itself – the files found in this git repository – as well as the thinRoot images are licensed under the conditions of the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0). Please note, however, that the buildroot distribution thinRoot is using is licensed under the [GPLv2](http://www.gnu.org/licenses/gpl-2.0.html) license instead.

## :family: Authors
See [Contributors](https://github.com/jens-maus/thinRoot/graphs/contributors) for a complete list of people that have directly contributed to this project.
