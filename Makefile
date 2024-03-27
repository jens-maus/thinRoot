BUILDROOT_VERSION=2024.02.1
BUILDROOT_SHA256=4c9f3a3bc19462a9bf838d7f37996c49c68a63af9f9e6c254ee76e0e02cd8194
BUILDROOT_EXTERNAL=buildroot-external
DEFCONFIG_DIR=$(BUILDROOT_EXTERNAL)/configs
DATE=$(shell date +%Y%m%d)
PRODUCT=
PRODUCT_VERSION=${DATE}
PRODUCTS:=$(sort $(notdir $(patsubst %.config,%,$(wildcard $(DEFCONFIG_DIR)/*.config))))
BR2_DL_DIR=$(shell pwd)/download
BR2_CCACHE_DIR=${HOME}/.buildroot-ccache
BR2_JLEVEL=$(shell nproc)

ifneq ($(PRODUCT),)
	PRODUCTS:=$(PRODUCT)
else
	PRODUCT:=$(firstword $(PRODUCTS))
endif

.NOTPARALLEL: $(PRODUCTS) $(addsuffix -release, $(PRODUCTS)) $(addsuffix -clean, $(PRODUCTS)) build-all clean-all release-all
.PHONY: all build release clean clean-all distclean help updatePkg

all: help

buildroot-$(BUILDROOT_VERSION).tar.gz: $(BR2_DL_DIR)
	@echo "[downloading buildroot-$(BUILDROOT_VERSION).tar.gz]"
	wget https://github.com/buildroot/buildroot/archive/refs/tags/$(BUILDROOT_VERSION).tar.gz -O buildroot-$(BUILDROOT_VERSION).tar.gz
	echo "$(BUILDROOT_SHA256)  buildroot-$(BUILDROOT_VERSION).tar.gz" >buildroot-$(BUILDROOT_VERSION).tar.gz.sign
	shasum -a 256 -c buildroot-$(BUILDROOT_VERSION).tar.gz.sign

buildroot-$(BUILDROOT_VERSION): | buildroot-$(BUILDROOT_VERSION).tar.gz
	@echo "[patching buildroot-$(BUILDROOT_VERSION)]"
	if [ ! -d $@ ]; then tar xf buildroot-$(BUILDROOT_VERSION).tar.gz; for p in $(sort $(wildcard buildroot-patches/*.patch)); do echo "\nApplying $${p}"; patch -d buildroot-$(BUILDROOT_VERSION) --remove-empty-files -p1 < $${p} || exit 127; [ ! -x $${p%.*}.sh ] || $${p%.*}.sh buildroot-$(BUILDROOT_VERSION); done; fi

build-$(PRODUCT): | buildroot-$(BUILDROOT_VERSION)
	mkdir $(shell pwd)/build-$(PRODUCT)

$(BR2_DL_DIR):
	@echo "[mkdir $(BR2_DL_DIR)]"
	test -e $(BR2_DL_DIR) || mkdir $(BR2_DL_DIR)

$(BR2_CCACHE_DIR):
	@echo "[mkdir $(BR2_CCACHE_DIR)]"
	test -e $(BR2_CCACHE_DIR) || mkdir $(BR2_CCACHE_DIR)

build-$(PRODUCT)/.config: | build-$(PRODUCT) $(BR2_CCACHE_DIR)
	@echo "[config $@]"
	cd $(shell pwd)/build-$(PRODUCT) && $(MAKE) O=$(shell pwd)/build-$(PRODUCT) -C ../buildroot-$(BUILDROOT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) PRODUCT=$(PRODUCT) PRODUCT_VERSION=$(PRODUCT_VERSION) alldefconfig
	cd $(shell pwd)/build-$(PRODUCT) && BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) PRODUCT=$(PRODUCT) PRODUCT_VERSION=$(PRODUCT_VERSION) ../buildroot-$(BUILDROOT_VERSION)/support/kconfig/merge_config.sh ../$(BUILDROOT_EXTERNAL)/Buildroot.config ../$(BUILDROOT_EXTERNAL)/configs/$(PRODUCT).config

build-all: $(PRODUCTS)
$(PRODUCTS): %:
	@echo "[build: $@]"
	@$(MAKE) PRODUCT=$@ PRODUCT_VERSION=$(PRODUCT_VERSION) build

build: | buildroot-$(BUILDROOT_VERSION) build-$(PRODUCT)/.config
	@echo "[build: $(PRODUCT)]"
ifneq ($(FAKE_BUILD),true)
	cd $(shell pwd)/build-$(PRODUCT) && $(MAKE) O=$(shell pwd)/build-$(PRODUCT) -C ../buildroot-$(BUILDROOT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) PRODUCT=$(PRODUCT) PRODUCT_VERSION=$(PRODUCT_VERSION)
else
	$(eval BOARD := $(shell echo $(PRODUCT) | cut -d'_' -f2-))
	# Dummy build - mainly for testing CI
	echo -n "FAKE_BUILD - generating fake release archives..."
	mkdir -p build-$(PRODUCT)/images
	echo DUMMY >build-$(PRODUCT)/images/sdcard.img
endif

release-all: $(addsuffix -release, $(PRODUCTS))
$(addsuffix -release, $(PRODUCTS)): %:
	@$(MAKE) PRODUCT=$(subst -release,,$@) PRODUCT_VERSION=$(PRODUCT_VERSION) release

release: build
	@echo "[creating release: $(PRODUCT)]"
	$(eval BOARD_DIR := $(BUILDROOT_EXTERNAL)/board/$(shell echo $(PRODUCT) | cut -d'_' -f2))
	if [ -x $(BOARD_DIR)/post-release.sh ]; then $(BOARD_DIR)/post-release.sh $(BOARD_DIR) ${PRODUCT} ${PRODUCT_VERSION}; fi

check-all: $(addsuffix -check, $(PRODUCTS))
$(addsuffix -check, $(PRODUCTS)): %:
	@$(MAKE) PRODUCT=$(subst -check,,$@) PRODUCT_VERSION=$(PRODUCT_VERSION) check

check: buildroot-$(BUILDROOT_VERSION) build-$(PRODUCT)/.config
	@echo "[checking: $(PRODUCT)]"
	$(eval BOARD_DIR := $(BUILDROOT_EXTERNAL)/board/$(shell echo $(PRODUCT) | cut -d'_' -f2))
	@echo "[checking status: $(BUILDROOT_EXTERNAL)]"
	buildroot-$(BUILDROOT_VERSION)/utils/check-package --exclude PackageHeader --br2-external $(BUILDROOT_EXTERNAL)/package/*/*

clean-all: $(addsuffix -clean, $(PRODUCTS))
$(addsuffix -clean, $(PRODUCTS)): %:
	@$(MAKE) PRODUCT=$(subst -clean,,$@) PRODUCT_VERSION=$(PRODUCT_VERSION) clean

clean:
	@echo "[clean $(PRODUCT)]"
	@rm -rf build-$(PRODUCT)

distclean: clean-all
	@echo "[distclean]"
	@rm -rf buildroot-$(BUILDROOT_VERSION)
	@rm -f buildroot-$(BUILDROOT_VERSION).tar.*
	@rm -rf $(BR2_DL_DIR)

.PHONY: menuconfig
menuconfig: buildroot-$(BUILDROOT_VERSION) build-$(PRODUCT)/.config
	cd $(shell pwd)/build-$(PRODUCT) && $(MAKE) O=$(shell pwd)/build-$(PRODUCT) -C ../buildroot-$(BUILDROOT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) PRODUCT=$(PRODUCT) PRODUCT_VERSION=$(PRODUCT_VERSION) menuconfig

.PHONY: xconfig
xconfig: buildroot-$(BUILDROOT_VERSION) build-$(PRODUCT)/.config
	cd $(shell pwd)/build-$(PRODUCT) && $(MAKE) O=$(shell pwd)/build-$(PRODUCT) -C ../buildroot-$(BUILDROOT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) PRODUCT=$(PRODUCT) PRODUCT_VERSION=$(PRODUCT_VERSION) xconfig

.PHONY: savedefconfig
savedefconfig: buildroot-$(BUILDROOT_VERSION) build-$(PRODUCT)
	cd $(shell pwd)/build-$(PRODUCT) && $(MAKE) O=$(shell pwd)/build-$(PRODUCT) -C ../buildroot-$(BUILDROOT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) PRODUCT=$(PRODUCT) PRODUCT_VERSION=$(PRODUCT_VERSION) savedefconfig BR2_DEFCONFIG=../$(DEFCONFIG_DIR)/$(PRODUCT).config

.PHONY: toolchain
toolchain: buildroot-$(BUILDROOT_VERSION) build-$(PRODUCT)/.config
	cd $(shell pwd)/build-$(PRODUCT) && $(MAKE) O=$(shell pwd)/build-$(PRODUCT) -C ../buildroot-$(BUILDROOT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) PRODUCT=$(PRODUCT) PRODUCT_VERSION=$(PRODUCT_VERSION) toolchain

.PHONY: linux-check-dotconfig
linux-check-dotconfig: buildroot-$(BUILDROOT_VERSION) build-$(PRODUCT)
	cd $(shell pwd)/build-$(PRODUCT) && $(MAKE) O=$(shell pwd)/build-$(PRODUCT) -C ../buildroot-$(BUILDROOT_VERSION) BR2_EXTERNAL=../$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_CCACHE_DIR=$(BR2_CCACHE_DIR) BR2_JLEVEL=$(BR2_JLEVEL) PRODUCT=$(PRODUCT) PRODUCT_VERSION=$(PRODUCT_VERSION) linux-check-dotconfig BR2_DEFCONFIG=../$(DEFCONFIG_DIR)/$(PRODUCT).config BR2_CHECK_DOTCONFIG_OPTS="--github-format --strip-path-prefix=$(PWD)/"

# Create a fallback target (%) to forward all unknown target calls to the build Makefile.
# This includes:
#   linux-menuconfig
#   linux-update-defconfig
#   busybox-menuconfig
#   busybox-update-config
#   uboot-menuconfig
#   uboot-update-defconfig
linux-menuconfig linux-update-defconfig busybox-menuconfig busybox-update-config uboot-menuconfig uboot-update-defconfig legal-info:
	@echo "[$@ $(PRODUCT)]"
	@$(MAKE) -C build-$(PRODUCT) PRODUCT=$(PRODUCT) PRODUCT_VERSION=$(PRODUCT_VERSION) $@

help:
	@echo "thinRoot Build Environment"
	@echo
	@echo "Usage:"
	@echo "  $(MAKE) <product>: build+create image for selected product"
	@echo "  $(MAKE) build-all: run build for all supported products"
	@echo
	@echo "  $(MAKE) <product>-release: build+create release archive for product"
	@echo "  $(MAKE) release-all: build+create release archive for all supported products"
	@echo
	@echo "  $(MAKE) <product>-check: run ci consistency check for product"
	@echo "  $(MAKE) check-all: run ci consistency check all supported platforms"
	@echo
	@echo "  $(MAKE) <product>-clean: remove build directory for product"
	@echo "  $(MAKE) clean-all: remove build directories for all supported platforms"
	@echo
	@echo "  $(MAKE) distclean: clean everything (all build dirs and buildroot sources)"
	@echo
	@echo "  $(MAKE) PRODUCT=<product> menuconfig: change buildroot config options"
	@echo "  $(MAKE) PRODUCT=<product> savedefconfig: update buildroot defconfig file"
	@echo "  $(MAKE) PRODUCT=<product> linux-menuconfig: change linux kernel config option"
	@echo "  $(MAKE) PRODUCT=<product> linux-update-defconfig: update linux kernel defconfig file"
	@echo "  $(MAKE) PRODUCT=<product> linux-check-dotconfig: checks dotconfig files against Kconfig"
	@echo "  $(MAKE) PRODUCT=<product> busybox-menuconfig: change busybox config options"
	@echo "  $(MAKE) PRODUCT=<product> busybox-update-config: update busybox defconfig file"
	@echo "  $(MAKE) PRODUCT=<product> uboot-menuconfig: change u-boot config options"
	@echo "  $(MAKE) PRODUCT=<product> uboot-update-defconfig: update u-boot defconfig file"
	@echo
	@echo "  $(MAKE) PRODUCT=<product> legal-info: update legal information file"
	@echo
	@echo "Supported products: $(PRODUCTS)"
