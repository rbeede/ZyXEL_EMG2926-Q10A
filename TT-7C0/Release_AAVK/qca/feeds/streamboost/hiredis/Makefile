include $(TOPDIR)/rules.mk

PKG_NAME:=hiredis
PKG_VERSION:=bf161d996fcab9cf351b2fdb851a9db5f275103b
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_VERSION).tar.gz
#PKG_SOURCE_URL:=https://github.com/redis/hiredis/archive
#PKG_MD5SUM:=c8cca2e52d86c6ed3718de14595e81df
PKG_CAT:=zcat

PKG_BUILD_DIR:=$(BUILD_DIR)/hiredis-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/hiredis
  SECTION:=libs
  CATEGORY:=Libraries
  SUBMENU:=database
  TITLE:=hiredis
  MAINTAINER:=Cristian Prundeanu <c.p@qca.qualcomm.com>
  URL:=https://github.com/redis/hiredis
endef

export ARCH=

define Build/InstallDev
	$(MAKE) -C $(PKG_BUILD_DIR) \
		PREFIX="$(1)/usr" \
		install
endef

define Package/hiredis/install
	$(INSTALL_DIR) $(PKG_BUILD_DIR)/tmp-install
	$(MAKE) -C $(PKG_BUILD_DIR) \
		PREFIX=$(PKG_BUILD_DIR)/tmp-install \
		install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/tmp-install/lib/*.so $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/tmp-install/lib/*.so.* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,hiredis))
