# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id$
	
include $(TOPDIR)/rules.mk

#These lines concatanate the package name and list the URL location from which the package source code is to be downloaded
PKG_NAME:=inadyn
PKG_VERSION:=1.96.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2

PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
DL_DIR:=$(TOPDIR)/dl

PATCH_DIR:=patches

include $(INCLUDE_DIR)/package.mk

define Package/inadyn
SECTION:=net
CATEGORY:=Base system
TITLE:=INADYN is a free DynDNS client.
endef

define Package/inadyn/compile

	$(MAKE) -C $(PKG_BUILD_DIR) \
        CC="$(TARGET_CC)" \
        CROSS_COMPILE="$(TARGET_CROSS)" \
        EXTRA_CFLAGS="$(TARGET_CFLAGS)" \
        ARCH="$(ARCH)" \
        IPKG_ARCH="$(ARCH)" \
        all
endef

define Package/inadyn/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/linux/inadyn $(1)/bin
endef

$(eval $(call BuildPackage,inadyn))
