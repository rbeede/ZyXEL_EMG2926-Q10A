include $(TOPDIR)/rules.mk

PKG_NAME:=netifd
PKG_VERSION:=2012-12-17.1
PKG_RELEASE=$(PKG_SOURCE_VERSION)

#PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=git://nbd.name/luci2/netifd.git
#PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION1:=2eca28705a27ab37ee902308af2c134c64c95e61
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION1).tar.gz
PKG_MAINTAINER:=Felix Fietkau <nbd@openwrt.org>
# PKG_MIRROR_MD5SUM:=
# CMAKE_INSTALL:=1
PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/netifd
  SECTION:=base
  CATEGORY:=Base system
  DEPENDS:=+libuci +libnl-tiny +libubus +ubus +ubusd +jshn
  TITLE:=OpenWrt Network Interface Configuration Daemon
endef

TARGET_CFLAGS += \
	-I$(STAGING_DIR)/usr/include/libnl-tiny \
	-I$(STAGING_DIR)/usr/include

CMAKE_OPTIONS += \
	-DLIBNL_LIBS=-lnl-tiny \
	-DDEBUG=1

define Package/netifd/install

	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/netifd $(1)/sbin/
	$(CP) ./files/* $(1)/
	$(CP) $(PKG_BUILD_DIR)/dummy/netifd-proto.sh $(1)/lib/netifd/

ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg2926aavk")
	cp -rf $(TOPDIR)/package/network/config/netifd/ZyXEL_Models/dhcp.script_EMG2926aavk $(1)/lib/netifd/dhcp.script
	cp -rf $(TOPDIR)/package/network/config/netifd/ZyXEL_Models/sbin/ifup  $(1)/sbin/ifup
	cp -rf $(TOPDIR)/package/network/config/netifd/ZyXEL_Models/dhcp.sh  $(1)/lib/netifd/proto/dhcp.sh
	cp -rf $(TOPDIR)/package/network/config/netifd/ZyXEL_Models/netifd-proto.sh  $(1)/lib/netifd/netifd-proto.sh
else  ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg3425aayj")
	cp -rf $(TOPDIR)/package/network/config/netifd/ZyXEL_Models/dhcp.script_EMG3425aayj $(1)/lib/netifd/dhcp.script
	cp -rf $(TOPDIR)/package/network/config/netifd/ZyXEL_Models/sbin/ifup  $(1)/sbin/ifup
	cp -rf $(TOPDIR)/package/network/config/netifd/ZyXEL_Models/dhcp.sh  $(1)/lib/netifd/proto/dhcp.sh
	cp -rf $(TOPDIR)/package/network/config/netifd/ZyXEL_Models/ppp.sh_EMG3425aayj  $(1)/lib/netifd/proto/ppp.sh
	cp -rf $(TOPDIR)/package/network/config/netifd/ZyXEL_Models/netifd-proto.sh  $(1)/lib/netifd/netifd-proto.sh
	
endif

endef

$(eval $(call BuildPackage,netifd))
