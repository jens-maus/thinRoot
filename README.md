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

_thinRoot_ is a buildroot (https://buildroot.org/) powered operating system environment to create lightweight user-defined kiosk systems for PXE bootable ThinClients (e.g. using intel NUC, RaspberryPi, etc.) to smoothly connect to server-based desktop environments using ThinLinc, RDP, VNC, etc....

## :cookie: Features
* provides a lightweight kiosk system which after bootup provides a simple connection GUI with options to connect via [ThinLinc](http://www.cendio.se/), RDP (via [freerdp](http://www.freerdp.com)) and VNC to Linux and Windows Terminalservers

## :fire: Limitations
* ...

## :computer: Requirements

1. One of the following PXE capable/enabled ThinClient hardware:
  * 8th Gen Intel NUC (Coffee Lake): [NUC8i3BEK/NUC8i3BEH](https://www.intel.com/content/www/us/en/products/boards-kits/nuc/kits/nuc8i3bek.html)
  * 7th Gen Intel NUC (Kaby Lake): [NUC7i3BNK/NUC7i3BNH](https://www.intel.com/content/www/us/en/products/boards-kits/nuc/kits/nuc7i3bnk.html)
  * 6th Gen Intel NUC (Skylake): [NUC6i3SYB/NUC6i5SYB](https://www.intel.com/content/www/us/en/products/boards-kits/nuc/kits/nuc6i3syk.html)
  * 5th Gen Intel NUC (Broadwell): [NUC5i3RYB/NUC5i5RYB](http://www.intel.de/content/www/us/en/nuc/nuc-kit-nuc5i3ryk.html)
  * 4th Gen Intel NUC (Haswell): [D34010WYB/D54250WYB](http://www.intel.de/content/www/us/en/nuc/nuc-kit-d34010wykh-board-d34010wyb.html)
  * 3th Gen Intel NUC (Atom): [DE3815TYBE](http://www.intel.de/content/www/us/en/nuc/nuc-kit-de3815tykhe-board-de3815tybe.html)
  * 2th Gen Intel NUC (Ivy Bridge): [D33217GK](http://www.intel.com/content/www/us/en/support/boards-and-kits/intel-nuc-boards/intel-nuc-board-d33217gk.html)
  * 1st Gen Intel NUC (Sandy Bridge): [DCP847SKE](http://www.intel.de/content/www/us/en/nuc/nuc-kit-dccp847dye-board-dcp847ske.html)
2. A PXE+TFTP+DHCP based server environment to host the final PXE image for the bootable ThinClient.
3. A server-based desktop environment to connect to (e.g. Linux via ThinLinc, Windows via RDP, etc.).

## :cloud: Installation
The installation of thinRoot is quite straight forward as it is delivered as a full PXE bootable system image that can be directly booted using a PXE+TFTP+DHCP environment:

1. [Download latest release](https://github.com/jens-maus/thinRoot/releases) archive for the hardware platform you are using:
2. Unarchive tar.bz2 file resulting in a 'bzImage' file to be bootable via a standard PXE environment.

## :yum: How to contribute
As the thinRoot project is an open source based project everyone is invited to contribute to this project. So, if you are a talented developer and want to contribute to the success of thinRoot feel free to send over pull requests or report issues / enhancement requests. Please note, however, the licensing and contributing implications and accept that - in short - anything you contribute to this repository/project (especially source code) will be (re)licensed under the Apache 2.0 license (see [CONTRIBUTING.md](CONTRIBUTING.md)). In addition, please understand that we will only accept contributions (either source code or issues in the issue tracker) if these comply to our [CODE OF CONDUCT](CODE_OF_CONDUCT.md).

### :moneybag: Donations [![Donate](https://img.shields.io/badge/donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RAQSDY9YNZVCL)
Even for those that don't have the technical knowhow to help developing on thinRoot there are ways to support our development. Please consider sending us a donation to not only help us to compensate for expenses regarding thinRoot, but also to keep our general development motivation on a high level. So if you want to donate some money please feel free to send us money via [PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RAQSDY9YNZVCL). And if you are running a business which might integrate thinRoot in one of your products please contact us for a regular donation plan which could not only show that you do care about open source development, but also could secure your product by ensuring that development on thinRoot continues in future.

### :construction: Development
Building your own thinRoot SD card image is a very straight forward process using this build environment – given that you have sufficient Linux/Unix knowledge and you know what you are actually doing. But if you know what you are doing and which host tools are required to actually be able to run a thinRoot build, it should be as simple as:

```sh
$ git clone https://github.com/jens-maus/thinRoot
$ cd thinRoot
$ make dist
[wait up to 1h]
$ cp build-intel_nuc/images/bzImage /tftpboot/thinroot/
```

## :scroll: License
The thinRoot build environment itself – the files found in this git repository – as well as the thinRoot images are licensed under the conditions of the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0). Please note, however, that the buildroot distribution thinRoot is using is licensed under the [GPLv2](http://www.gnu.org/licenses/gpl-2.0.html) license instead.

## :family: Authors
See [Contributors](https://github.com/jens-maus/thinRoot/graphs/contributors) for a complete list of people that have directly contributed to this project.
