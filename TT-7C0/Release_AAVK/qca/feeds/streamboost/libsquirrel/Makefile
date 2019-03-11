include $(TOPDIR)/rules.mk

PKG_NAME:=libsquirrel
#PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=ssh://qca-git01.qualcomm.com:29418/streamboost/libsquirrel
PKG_BRANCH:=banana
PKG_RELEASE:=1

include $(INCLUDE_DIR)/local-development.mk
ifeq ($(DUMP)$(PKG_VERSION),)
PKG_REV:=0108fb7
PKG_VERSION:=g0108fb7
endif
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_MIRROR:=none

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/libsquirrel
  SECTION:=Bigfoot
  CATEGORY:=Bigfoot
  SUBMENU:=Utilities
  TITLE:=Configuration file decryption library.
  DEPENDS:=+libopenssl
  MAINTAINER:=Mo Chen <moc@qca.qualcomm.com>
endef

define Package/libsquirrel/description
 This package contains a library for decrypting Streamboost daemon configuration files.
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libsquirrel.so* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/include/* $(1)/usr/include/
endef

define Package/libsquirrel/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libsquirrel.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libsquirrel))
