# Makefile for OpenWrt
#
# Copyright (C) 2007 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

TOPDIR:=${CURDIR}
LC_ALL:=C
LANG:=C
#SVN_REPOSITORY_ROOT:=$(shell svn info | grep "Repository Root:" | cut -d' ' -f3)
export TOPDIR LC_ALL LANG SVN_REPOSITORY_ROOT

empty:=
space:= $(empty) $(empty)
$(if $(findstring $(space),$(TOPDIR)),$(error ERROR: The path to the OpenWrt directory must not include any spaces))

world:

include $(TOPDIR)/include/host.mk

ifneq ($(OPENWRT_BUILD),1)
  # XXX: these three lines are normally defined by rules.mk
  # but we can't include that file in this context
  empty:=
  space:= $(empty) $(empty)
  _SINGLE=export MAKEFLAGS=$(space);

  override OPENWRT_BUILD=1
  export OPENWRT_BUILD
  GREP_OPTIONS=
  export GREP_OPTIONS
  include $(TOPDIR)/include/debug.mk
  include $(TOPDIR)/include/depends.mk
  include $(TOPDIR)/include/toplevel.mk
else
  include rules.mk
  include $(INCLUDE_DIR)/depends.mk
  include $(INCLUDE_DIR)/subdir.mk
  include target/Makefile
  include package/Makefile
  include tools/Makefile
  include toolchain/Makefile

$(toolchain/stamp-install): $(tools/stamp-install)
$(target/stamp-compile): $(toolchain/stamp-install) $(tools/stamp-install) $(BUILD_DIR)/.prepared $(BUILD_DIR)/zyxel-gui-ck
$(package/stamp-compile): $(target/stamp-compile) $(package/stamp-cleanup)
$(package/stamp-install): $(package/stamp-compile)
$(target/stamp-install): $(package/stamp-compile) $(package/stamp-install)

printdb:
	@true

prepare: $(target/stamp-compile)

clean: FORCE
	rm -rf $(BUILD_DIR) $(BIN_DIR) $(BUILD_LOG_DIR)

dirclean: clean
	rm -rf $(STAGING_DIR) $(STAGING_DIR_HOST) $(STAGING_DIR_TOOLCHAIN) $(TOOLCHAIN_DIR) $(BUILD_DIR_HOST) $(BUILD_DIR_TOOLCHAIN)
	rm -rf $(TMP_DIR)

ifndef DUMP_TARGET_DB
$(BUILD_DIR)/.prepared: Makefile
	@mkdir -p $$(dirname $@)
	@touch $@

$(BUILD_DIR)/zyxel-gui-ck: FORCE
	@rm -f $(BUILD_DIR)/*-luci-0.9+svn6252/.prepared*

tmp/.prereq_packages: .config
	unset ERROR; \
	for package in $(sort $(prereq-y) $(prereq-m)); do \
		$(_SINGLE)$(NO_TRACE_MAKE) -s -r -C package/$$package prereq || ERROR=1; \
	done; \
	if [ -n "$$ERROR" ]; then \
		echo "Package prerequisite check failed."; \
		false; \
	fi
	touch $@
endif

# check prerequisites before starting to build
prereq: $(target/stamp-prereq) tmp/.prereq_packages

ifeq ("$(CONFIG_PACKAGE_zyxel_qos_sp)","y")

	@if [ ! -e "$(TOPDIR)/target/linux/ar71xx/patches-3.3/a20-Zyxel_QoS_Kernel.patch" ]; then \
		ln -s $(TOPDIR)/target/linux/ar71xx/ZyXEL_Models/a20-Zyxel_QoS_Kernel.patch $(TOPDIR)/target/linux/ar71xx/patches-3.3/a20-Zyxel_QoS_Kernel.patch ;\
	fi

	cp -rf $(TOPDIR)/target/linux/ar71xx/ZyXEL_Models/config-3.3 $(TOPDIR)/target/linux/ar71xx/

	@if [ ! -e "$(TOPDIR)/package/network/utils/iptables/patches/430-Patch_for_Qos.patch" ]; then \
		ln -s $(TOPDIR)/package/network/utils/iptables/ZyXEL_Models/430-Patch_for_Qos.patch \
		$(TOPDIR)/package/network/utils/iptables/patches/430-Patch_for_Qos.patch ;\
	fi

	@if [ ! -e "$(TOPDIR)/target/linux/ar71xx/patches-3.3/a21-Zyxel_Log_Kernel.patch" ]; then \
		ln -s $(TOPDIR)/target/linux/ar71xx/ZyXEL_Models/a21-Zyxel_Log_Kernel.patch $(TOPDIR)/target/linux/ar71xx/patches-3.3/a21-Zyxel_Log_Kernel.patch ;\
	fi

endif

ifeq ("$(CONFIG_PACKAGE_qca-ssdk-shell)","y")
ifeq ("$(CONFIG_TARGET_ar71xx_generic_NBG6616)","y")
	$(info Project is NBG6616.)
else ifeq ("$(CONFIG_TARGET_ar71xx_generic_NBG6716)","y")
	$(info Project is NBG6716.)
else
	@if [ ! -e "$(TOPDIR)/target/linux/ar71xx/patches-3.3/a13_fix_RGMII_traffic.patch" ]; then \
		ln -s $(TOPDIR)/target/linux/ar71xx/ZyXEL_Models/a13_fix_RGMII_traffic.patch $(TOPDIR)/target/linux/ar71xx/patches-3.3/a13_fix_RGMII_traffic.patch ;\
	fi
	@if [ ! -e "$(TOPDIR)/target/linux/ar71xx/patches-3.3/a13_fix_RGMII_traffic_emg3425aayj.patch" ]; then \
		ln -s $(TOPDIR)/target/linux/ar71xx/ZyXEL_Models/a13_fix_RGMII_traffic_emg3425aayj.patch $(TOPDIR)/target/linux/ar71xx/patches-3.3/a13_fix_RGMII_traffic_emg3425aayj.patch ;\
	fi
endif
endif

ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg3425aayj")

	@if [ ! -e "$(TOPDIR)/target/linux/ar71xx/patches-3.3/a26-Zyxel_WAN_ingress_traffic_police.patch" ]; then \
		ln -s $(TOPDIR)/target/linux/ar71xx/ZyXEL_Models/a26-Zyxel_WAN_ingress_traffic_police.patch $(TOPDIR)/target/linux/ar71xx/patches-3.3/a26-Zyxel_WAN_ingress_traffic_police.patch ;\
	fi
	
endif

	@if [ ! -f "$(INCLUDE_DIR)/site/$(REAL_GNU_TARGET_NAME)" ]; then \
		echo 'ERROR: Missing site config for target "$(REAL_GNU_TARGET_NAME)" !'; \
		echo '       The missing file will cause configure scripts to fail during compilation.'; \
		echo '       Please provide a "$(INCLUDE_DIR)/site/$(REAL_GNU_TARGET_NAME)" file and restart the build.'; \
		exit 1; \
	fi

prepare: .config $(tools/stamp-install) $(toolchain/stamp-install)
world:	prepare $(target/stamp-compile) $(package/stamp-compile) $(package/stamp-install) $(target/stamp-install) FORCE
	$(_SINGLE)$(SUBMAKE) -r package/index

# update all feeds, re-create index files, install symlinks
package/symlinks:
	$(SCRIPT_DIR)/feeds update -a
	$(SCRIPT_DIR)/feeds install -a

# re-create index files, install symlinks
package/symlinks-install:
	$(SCRIPT_DIR)/feeds update -i
	$(SCRIPT_DIR)/feeds install -a

# remove all symlinks, don't touch ./feeds
package/symlinks-clean:
	$(SCRIPT_DIR)/feeds uninstall -a

.PHONY: clean dirclean prereq prepare world package/symlinks package/symlinks-install package/symlinks-clean

endif
