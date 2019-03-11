# 
# Copyright (C) 2006-2007 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/target.mk

export TARGET_BUILD=1

WEB_PATH=WEB
WEB_COMPRESS_PATH=$(WEB_PATH).tar.bz2
WEB_WWW_NAME=www
WEB_LUCI_NAME=luci
WEB_LUCI_PATH=usr/lib/lua

prereq clean download prepare compile menuconfig nconfig oldconfig update refresh: FORCE
	@+$(NO_TRACE_MAKE) -C $(BOARD) $@

install: FORCE
ifeq ($(CONFIG_PACKAGE_project_NBG6616),y)
ifeq (,$(wildcard $(TARGET_DIR)/$(WEB_COMPRESS_PATH)))
	mkdir $(WEB_PATH)
	cp -r $(TARGET_DIR)/$(WEB_WWW_NAME) $(WEB_PATH)
	cp -r $(TARGET_DIR)/$(WEB_LUCI_PATH)/$(WEB_LUCI_NAME) $(WEB_PATH)
	tar jcvf $(WEB_COMPRESS_PATH) $(WEB_PATH)
	ln -s /tmp/$(WEB_PATH)/$(WEB_WWW_NAME) $(WEB_WWW_NAME)
	ln -s /tmp/$(WEB_PATH)/$(WEB_LUCI_NAME) $(WEB_LUCI_NAME)

	rm -rf $(TARGET_DIR)/$(WEB_WWW_NAME) $(TARGET_DIR)/$(WEB_LUCI_PATH)/$(WEB_LUCI_NAME)
	mv $(WEB_COMPRESS_PATH) $(TARGET_DIR)
	mv $(WEB_WWW_NAME) $(TARGET_DIR)
	mv $(WEB_LUCI_NAME) $(TARGET_DIR)/$(WEB_LUCI_PATH)
	rm -rf $(WEB_PATH)
endif
endif
	@+$(NO_TRACE_MAKE) -C $(BOARD) $@
