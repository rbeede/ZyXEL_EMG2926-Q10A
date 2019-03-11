#
# Copyright (C) 2008-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk

PKG_NAME:=lldt

PKG_VERSION:=0.1
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

include $(INCLUDE_DIR)/package.mk

define Package/lldt
  SECTION:=net
  CATEGORY:=Base system
  URL:=http://openwrt.org/
  TITLE:=OpenWrt lldt
  PKGARCH:=all
endef

define Package/lldt/description
 Microsoft Link Layer Discovery Protocol for network topology
endef

define Package/lldt/conffiles
/etc_ro/lld2d.conf
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		depend
	$(MAKE) -C $(PKG_BUILD_DIR) \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		all
endef

define Package/lldt/install
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lld2d $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lld2test $(1)/sbin
	$(INSTALL_BIN) ./files/lltd.sh $(1)/sbin
	$(INSTALL_DIR) $(1)/etc_ro
	$(INSTALL_DATA) ./files/lld2d.conf $(1)/etc_ro
	$(INSTALL_DATA) ./files/icon.ico $(1)/etc_ro
	$(INSTALL_DATA) ./files/icon.large.ico $(1)/etc_ro
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/lldt.init $(1)/etc/init.d/lldt
endef

$(eval $(call BuildPackage,lldt))
