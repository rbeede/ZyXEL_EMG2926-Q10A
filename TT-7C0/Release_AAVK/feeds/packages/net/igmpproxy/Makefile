#
# Copyright (C) 2006-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=igmpproxy
PKG_VERSION:=0.1
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD
PKG_MD5SUM:=c56f41ec195bc1fe016369bf74efc5a1

include $(INCLUDE_DIR)/package.mk

define Package/igmpproxy
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=Multicast Routing Daemon
  URL:=http://sourceforge.net/projects/igmpproxy
endef

define Package/igmpproxy/description
	IGMPproxy is a simple dynamic Multicast Routing Daemon using
	only IGMP signalling (Internet Group Management Protocol).
endef

define Package/igmpproxy/conffiles
/etc/igmpproxy.conf
endef

TARGET_CFLAGS += -Dlog=igmpproxy_log

define Build/Compile	
	$(MAKE) -C $(PKG_BUILD_DIR)/src \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -std=gnu99"
endef

ifeq ($(CONFIG_PACKAGE_zyxel_multiwan),y)
	TARGET_CFLAGS += -DZYXEL_IGMP_STATUS
endif

define Package/igmpproxy/install	
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_CONF) ./files/igmpproxy.conf $(1)/etc/
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/igmpproxy $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/etc/config

ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg2926aavk")
	$(INSTALL_BIN) ./files/act_igmp_EMG2926aavk $(1)/sbin/act_igmp
	$(INSTALL_CONF) ./files/igmpproxy.config_EMG2926aavk $(1)/etc/config/igmpproxy
	$(INSTALL_DATA) ./files/igmpproxy.hotplug_emg2926aavk $(1)/etc/hotplug.d/iface/25-igmpproxy
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/igmpproxy.init_emg2926aavk $(1)/etc/init.d/igmpproxy
else ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg3425aayj")
	$(INSTALL_BIN) ./files/act_igmp_EMG2926aavk $(1)/sbin/act_igmp
	$(INSTALL_CONF) ./files/igmpproxy.config_EMG2926aavk $(1)/etc/config/igmpproxy
	$(INSTALL_DATA) ./files/igmpproxy.hotplug_emg2926aavk $(1)/etc/hotplug.d/iface/25-igmpproxy
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/igmpproxy.init_emg2926aavk $(1)/etc/init.d/igmpproxy
else
	$(INSTALL_BIN) ./files/act_igmp $(1)/sbin/
	$(INSTALL_CONF) ./files/igmpproxy.config $(1)/etc/config/igmpproxy
	$(INSTALL_DATA) ./files/igmpproxy.hotplug $(1)/etc/hotplug.d/iface/25-igmpproxy
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/igmpproxy.init $(1)/etc/init.d/igmpproxy
endif

endef

$(eval $(call BuildPackage,igmpproxy))
