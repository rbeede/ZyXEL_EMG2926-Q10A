#
# Copyright (C) 2006-2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
	
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/zyxel-private.mk

PKG_NAME:=release-file
PKG_VERSION:=0.1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
RELEASE_FILE_DIR:=$(PKG_BUILD_DIR)/ipkg_file

define Package/release-file
SECTION:=net
CATEGORY:=Zyxel Packages
TITLE:=This is a release package
endef

define Build/Prepare
	@echo "---------!!! TODO: prepare ipkg !!!----------"
	mkdir -p $(PKG_BUILD_DIR)
	if [ ! -d "$(TOPDIR)/package/private" ]; then \
		$(CP) ./src/* $(PKG_BUILD_DIR); \
		cd "$(RELEASE_FILE_DIR)"; \
		for i in $$$$( ls ) ; do \
				tar -xf $$$$i; \
				mkdir tmp; \
				tar -zxvf data.tar.gz -C tmp; \
				rm  $$$$i; \
				rm control.tar.gz; \
				rm data.tar.gz; \
		done; \
	fi
	mkdir -p $(STAGING_DIR_HOST)/bin/
	$(CP) ./file/genImgHdr $(STAGING_DIR_HOST)/bin/
endef

define Build/Compile/Default
endef

define Build/Compile
	$(call Build/Compile/Default)
endef
	
define Package/release-file/install
	@echo "---------!!! TODO: install ipkg !!!----------"
	$(INSTALL_DIR) $(1)/
	$(CP) -rf $(RELEASE_FILE_DIR)/tmp/* $(1)/ 
endef

$(eval $(call BuildPackage,release-file))
