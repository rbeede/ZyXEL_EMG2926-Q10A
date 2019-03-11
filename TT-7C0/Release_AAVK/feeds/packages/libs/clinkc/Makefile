include $(TOPDIR)/rules.mk

PKG_NAME:=clinkc
PKG_VERSION:=2.4
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
#PKG_SOURCE_URL:=@ZyXEL_SITE/opensource/libs
PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

DL_DIR:=$(TOPDIR)/dl

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/clinkc
 SECTION:=libs
 CATEGORY:=Libraries
 TITLE:=HTTP general library
 DEPENDS:=+expat
# DEPENDS:=+expat +libopenssl +libuuid
endef

#ZHTTPD_CFLAGS:=-DZYXEL_PATCH -DCG_USE_OPENSSL -DCG_HAVE_SENDFILE -DHAVE_LIBUUID -std=gnu99
ZHTTPD_CFLAGS:=-DZYXEL_PATCH
# define maximum client thread create
#    0 => no limit
ZHTTPD_CFLAGS += -DCG_CLIENT_THREAD_LIMIT=20
# define waiting time when the client thread size over limit , not use
# ZHTTPD_CFLAGS += -DCG_CLIENT_THREAD_WAIT_TIME=2000

ifeq ($(CONFIG_ZYXEL_USA_PRODUCT),y)
	ZHTTPD_CFLAGS += -DUSA_PRODUCT
endif

define Package/clinkc/description
	CyberLink for C is a development package for UPnP™ developers
endef

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	tar -zxvf $(DL_DIR)/$(PKG_SOURCE) -C $(BUILD_DIR)
	$(Build/Patch)
	rm -rf $(PKG_BUILD_DIR)/std $(PKG_BUILD_DIR)/testunit $(PKG_BUILD_DIR)/lib
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
	$(TARGET_CONFIGURE_OPTS) \
	CFLAGS="-I$(PKG_BUILD_DIR)/include/ \
                -I$(BUILD_DIR)/openssl-1.0.1c/include/ \
		-I$(BUILD_DIR)/expat-1.95.8/lib/ \
		-I$(BUILD_DIR)/libuuid/ \
		-fPIC \
		$(ZHTTPD_CFLAGS)" 
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/include/* $(1)/usr/include
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libclinkc.so* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
endef

define Package/clinkc/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libclinkc.so $(1)/usr/lib/
	$(STRIP) $(1)/usr/lib/libclinkc.so
#	$(INSTALL_DIR) $(1)/etc/cert
#	$(CP) $(PKG_BUILD_DIR)/ztest_https/cert/*.* $(1)/etc/cert
endef

$(eval $(call BuildPackage,clinkc))
