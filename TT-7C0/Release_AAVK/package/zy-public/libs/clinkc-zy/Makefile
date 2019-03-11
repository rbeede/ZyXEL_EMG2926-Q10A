include $(TOPDIR)/rules.mk

PKG_NAME:=clinkc-zy

PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)
#PKG_SOURCE_SUBDIR:=$(PKG_NAME)/src
#PKG_SOURCE:=package/private/zyxel/$(PKG_SOURCE_SUBDIR)

PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/clinkc-zy
	SECTION:=net
	CATEGORY:=Zyxel Packages
	TITLE:=ZyXEL support TR069
	DEPENDS:=+expat +libopenssl
endef

define Package/clinkc-zy/description
	ZyXEL Modify - support TR069
endef

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
	$(TARGET_CONFIGURE_OPTS) \
	CFLAGS="-I.\
                -I./include/ \
                -I$(BUILD_DIR)/openssl-1.0.1g/include/ \
		-I$(BUILD_DIR)/expat-2.0.1/lib/ \
		-fPIC \
		-DZYXEL_PATCH -DCG_USE_OPENSSL -DHAVE_LONGLONG" 
endef

define Package/clinkc-zy/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libclinkc.so $(1)/usr/lib/
endef

$(eval $(call BuildPackage,clinkc-zy))


