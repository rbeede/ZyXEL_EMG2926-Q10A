include $(TOPDIR)/rules.mk

PKG_NAME:=lzma-zy

PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)
#PKG_SOURCE_SUBDIR:=$(PKG_NAME)/src
#PKG_SOURCE:=package/private/zyxel/$(PKG_SOURCE_SUBDIR)

PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/lzma-zy
	SECTION:=net
	CATEGORY:=Zyxel Packages
	TITLE:=ZyXEL support TR069
	DEPENDS:=
endef

define Package/lzma-zy/description
	ZyXEL Modify - support TR069
endef

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
	$(TARGET_CONFIGURE_OPTS)
endef

define Package/lzma-zy/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/*.so $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(PKG_BUILD_DIR)/targetlzma $(1)/usr/bin/
endef

$(eval $(call BuildPackage,lzma-zy))


