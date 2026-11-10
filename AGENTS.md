# AGENTS.md

Guidance for AI coding agents (and humans) working on the thinRoot repository.

## Project overview

thinRoot is a [Buildroot](https://buildroot.org/) based, RAM-disk only Linux
distribution for network-booted ThinClients and web kiosks. It provides RDP
(FreeRDP 3), ThinLinc, VNC and SPICE clients behind the `qutselect` connection
GUI, or a single fullscreen browser. Systems boot via PXE/TFTP/HTTP (x86_64) or
U-Boot (Raspberry Pi) and fetch per-host configuration from a boot server at
runtime.

The repository does **not** contain Buildroot itself. The top-level `Makefile`
downloads a pinned Buildroot release tarball, verifies its SHA256, applies the
patches from `buildroot-patches/` and then builds using `buildroot-external/`
as `BR2_EXTERNAL` tree (name `THINROOT`, path variable
`$(BR2_EXTERNAL_THINROOT_PATH)`).

Supported products (one per file in `buildroot-external/configs/`):
`generic-x86_64`, `rpi3`, `rpi4`, `rpi5`.

## Repository layout

| Path | Purpose |
| --- | --- |
| `Makefile` | Build entry point; pins `BUILDROOT_VERSION` / `BUILDROOT_SHA256`. |
| `buildroot-external/Buildroot.config` | Buildroot options shared by **all** products. |
| `buildroot-external/Busybox.config` | Shared BusyBox configuration. |
| `buildroot-external/configs/<product>.config` | Product-specific Buildroot options, merged on top of `Buildroot.config`. |
| `buildroot-external/board/<product>/` | Board files: `post-build.sh`, `post-image.sh`, `post-release.sh`, `kernel.config` fragment, `users_table.txt`, and for RPi `boot.cmd`, `bootEnv.txt`, `config.txt`, `cmdline.txt`, `genimage.cfg`, `uboot.config`, `kernel-patches/`. |
| `buildroot-external/kernel/<major.minor>/` | Shared Linux kernel config fragments (`global`, `device-support*`, `security*`). `6.18` is used by `generic-x86_64`, `6.6` by the RPi kernels. |
| `buildroot-external/package/<pkg>/` | Custom Buildroot packages (`Config.in`, `<pkg>.mk`, `<pkg>.hash`, optional patches/init scripts). |
| `buildroot-external/Config.in`, `Config.ext.in`, `external.mk` | Package menu registration and extra make targets (e.g. `linux-check-dotconfig`, CPU microcode embedding). |
| `buildroot-external/patches/<pkg>/` | `BR2_GLOBAL_PATCH_DIR`: patches/hash overrides for **upstream** Buildroot packages. |
| `buildroot-external/rootfs-overlay/` | Files copied verbatim into the target root filesystem (init scripts, X11/Openbox setup, helper scripts). |
| `buildroot-external/scripts/` | Python helpers (`check-dotconfig.py`, vendored `kconfiglib.py`). |
| `buildroot-patches/` | Patches applied to the Buildroot source tree itself (see below). |
| `scripts/update-*.sh` | Dependency bump scripts used by the `dependency-updates` workflow. |
| `tftpboot/` | Example PXE/iPXE/TFTP boot server setup (not part of the image build). |
| `docker/` | Boot server container (`ghcr.io/jens-maus/thinroot`): `Dockerfile` (builds iPXE from source, adds PXELINUX and the release images), entrypoint + generator scripts in `rootfs/`, smoke test in `tests/`. Built/published by `.github/workflows/container.yml`. |
| `release/` | Output directory for release images (contents are git-ignored). |

Generated / ignored directories: `build-<product>/`, `buildroot-<version>/`,
`buildroot-<version>.tar.gz*`, `download/`. Never commit them and never edit
files inside them as a "fix" — changes must go into the source tree above.

## Building

A full build needs a Linux host with the usual Buildroot host dependencies
(`wget bc cpio rsync zip python3 file`, a C/C++ toolchain, …), tens of GB of
disk space and roughly 1 hour or more per product. **Do not start a full build
unless explicitly asked**; prefer the cheap checks below.

```sh
make help                              # list all targets and products
make generic-x86_64                    # build one product
make generic-x86_64-release            # build + copy images to release/
make PRODUCT=rpi4 menuconfig           # edit Buildroot config interactively
make PRODUCT=rpi4 savedefconfig        # overwrite buildroot-external/configs/rpi4.config (see below)
make PRODUCT=rpi4 linux-menuconfig     # kernel config
make PRODUCT=rpi4 linux-check-dotconfig  # verify kernel fragments vs. Kconfig
make generic-x86_64-clean              # remove build-generic-x86_64/
make distclean                         # remove ALL build dirs, buildroot and download/ (destructive)
```

Useful variables: `PRODUCT`, `BR2_JLEVEL`, `BR2_DL_DIR` (default `./download`),
`BR2_CCACHE_DIR` (default `~/.buildroot-ccache`), `DATE` (release version,
default today as `YYYYMMDD`), and `FAKE_BUILD=true` to skip the real build
(used to test CI/release plumbing).

## Checks (run before committing)

CI (`.github/workflows/ci.yml`) runs on every push/PR that touches non-Markdown
files. Reproduce locally where possible:

```sh
# shell scripts (same excludes as CI)
shellcheck -e SC3010 -e SC3014 -e SC3057 -e SC3036 -e SC3028 -e SC3020 <files>

# YAML (config: .yamllint)
yamllint .

# Markdown (config: .markdownlint.yml)
markdownlint '**/*.md'

# boot server container (needs docker): build with a dummy image + smoke test
mkdir -p /tmp/payload && echo dummy >/tmp/payload/thinroot-19700101-generic-x86_64.img
docker buildx build -f docker/Dockerfile --build-context payload=/tmp/payload -t thinroot:test --load .
docker/tests/smoke-test.sh thinroot:test 19700101

# Buildroot package style – downloads and extracts Buildroot on first run;
# needs the Python modules flake8 and python-magic (pip install flake8 python-magic)
make check
```

`make check` runs Buildroot's `utils/check-package` over
`buildroot-external/package/*/*`. Snapshot builds additionally run
`linux-check-dotconfig`, so kernel config fragments must only contain symbols
that exist in the respective kernel's Kconfig.

## Conventions

### General

- Keep changes minimal and focused; this is an embedded image where size and
  boot time matter. Do not enable large packages without a clear reason.
- Prefer putting shared settings in `Buildroot.config` /
  `kernel/<ver>/*.config` and only product-specific deltas in
  `configs/<product>.config` / `board/<product>/kernel.config`. When a change
  applies to all RPi boards, update `rpi3`, `rpi4` **and** `rpi5`.
- Reference paths in configs via `$(BR2_EXTERNAL_THINROOT_PATH)/…`, never with
  absolute or `../` paths.
- Product config files are `savedefconfig` style: only non-default values
  that differ per product. `make PRODUCT=<p> savedefconfig` writes the
  *merged* configuration, so it also copies the non-default settings from
  `Buildroot.config` into `configs/<p>.config`. Review the result and remove
  those shared entries again (keep intentional product overrides), otherwise
  later changes to `Buildroot.config` are silently overridden. For small
  changes, editing the product config by hand is usually simpler.

### Custom Buildroot packages (`buildroot-external/package/`)

- Follow the [Buildroot manual](https://buildroot.org/downloads/manual/manual.html#adding-packages)
  coding style; `make check` (`check-package`) must pass.
- Every package needs `Config.in`, `<pkg>.mk` and a `<pkg>.hash` with `sha256`
  entries for the source archive **and** the license file(s).
- Register new packages in `buildroot-external/Config.in` (inside the
  `Additional software` menu); `.mk` files are picked up automatically by
  `external.mk`.
- Variable naming: `<PKG>_VERSION = …` (spaces around `=`); the update scripts
  and the dependency workflow parse these lines with regexes, so do not change
  their format.

### Patching upstream code

- **Upstream Buildroot packages:** put patches in
  `buildroot-external/patches/<package>/NNNN-description.patch`.
- **Buildroot core / package infrastructure:** use `buildroot-patches/`.
  Each `NNNN-name/` directory mirrors the Buildroot tree under `buildroot/`
  and contains the modified file next to an unmodified `*.orig` copy.
  Regenerate the corresponding `NNNN-name.patch` with
  `cd buildroot-patches && ./create_patches.sh` — do not hand-edit the
  `.patch` files. An optional executable `NNNN-name.sh` next to a patch is run
  after it is applied. Patches are applied in sorted order with `patch -p1`.
- After bumping `BUILDROOT_VERSION`, verify that all `buildroot-patches/*.patch`
  still apply and refresh the `*.orig` files if upstream changed.
  `make PRODUCT=<p> check` extracts the new Buildroot version and applies all
  patches, failing if one does not apply. Extraction and patching only happen
  if `buildroot-<version>/` does not exist yet, so to re-check (e.g. after a
  failed patch run) remove just that directory first
  (`rm -rf buildroot-<version>`). Do **not** use `make distclean` for this: it
  deletes all build directories and the download cache.
- **RPi kernel patches:** `buildroot-external/board/<rpi>/kernel-patches/`.

### Shell scripts

- Build-host scripts run on the build machine: `scripts/` and
  `buildroot-patches/*.sh` use `#!/bin/bash`, the `board/*/*.sh` hooks use
  `#!/bin/sh`. Keep the existing interpreter, use `set -e` and quote all
  expansions.
- Target scripts in `rootfs-overlay/` run under **BusyBox ash** (`#!/bin/sh`,
  annotate with `# shellcheck shell=dash` and targeted `disable=` where
  BusyBox-isms such as `[[ ]]` are used). Do not rely on GNU-only tools or
  Bash features unavailable in BusyBox.
- All scripts must pass shellcheck with the CI excludes above.

### Dependency updates

- `scripts/update-<name>.sh [version]` updates version and hashes in place.
  Without an argument it resolves the latest upstream release and exits early
  if nothing changed. Reuse helpers from `scripts/utils/utils.sh`.
- When adding a new auto-updated dependency, add a script and a matrix entry in
  `.github/workflows/dependency-updates.yml` (`slug`, `script`, `package`,
  `version_file`, `version_regex`).
- Version bumps are normally created automatically as PRs from
  `pr/dependency-update-*` branches; don't duplicate them manually.

### Commits and pull requests

- The author **and** committer of every commit is the human who requested or
  made the change (their name and e-mail address in `user.name`/`user.email`),
  never a tool or an AI assistant. Check `git config user.name` /
  `git config user.email` before committing and fix them if they point to a
  tool identity. Only the automated dependency/CI workflows
  (`github-actions[bot]`, `dependabot[bot]`) commit under their own identity.
- Commit messages, pull request titles and pull request descriptions must not
  mention or credit AI tools or language models: no `Co-Authored-By` trailers
  for tools, no "generated with/by" lines, no links to agent sessions. The same
  applies to issue and pull request comments and review replies an agent posts:
  no AI footers or "generated by" notes.
- Commit subjects are short, lower-case, imperative-ish English sentences,
  e.g. `bump freerdp3 to 3.33.1`, `add BR2_PACKAGE_ZSTD to fix …`,
  `remove obsolete … patch`.
- Mention the affected product(s) when a change is board specific.
- One logical change per pull request, ideally squashed into a single commit,
  referencing the related issue if there is one.
- Do not commit build outputs, downloaded archives or files from `release/`.
- Contributions are licensed under Apache-2.0 (see `LICENSE`); Buildroot itself
  is GPLv2.

## Runtime notes (useful when touching `rootfs-overlay/`)

- The whole system runs from an initramfs/RAM disk; there is no persistent
  storage by default.
- At boot, `etc/init.d/S42LoadNetFiles` derives `BASE_PATH` from the kernel
  command line (`BOOT_IMAGE` / `BASE_PATH`) and fetches from
  `${BASE_PATH}/conf/`: `thinroot.conf.network`, `thinroot.hosts` (hostname/MAC
  to group mapping) and `thinroot.conf.group-*`, `-<hostname>`, `-<ip>`,
  `-<mac>` files. Optional `overlay.pkg*` tarballs from `${BASE_PATH}` are
  extracted over `/`. All settings end up as environment files in
  `/etc/env.d`. Keep this mechanism backward compatible — deployed boot
  servers depend on it.
- The default unprivileged user is `truser` (see `board/*/users_table.txt`).
