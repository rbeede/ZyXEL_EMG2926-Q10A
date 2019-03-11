#
# Copyright (C) 2006-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

ifeq "$(PROFILE)" ""
PRODUCT_NAME=$(SUBTARGET)
else
PRODUCT_NAME=$(PROFILE)
endif

PKG_NAME:=miniupnpd
PKG_VERSION:=1.6.20110730
PKG_RELEASE:=4

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_MD5SUM:=8bd5c0447b6dc1101b96e958ee67d3ea
PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

PATCH_DIR:=patches-$(PRODUCT_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/miniupnpd
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+iptables +libip4tc
  TITLE:=Lightweight UPnP daemon
  SUBMENU:=Firewall
  URL:=http://miniupnp.free.fr/
  MAINTAINER:=Daniel Dickinson <openwrt@cshore.neomailbox.net>
endef

define Package/miniupnpd/conffiles
/etc/config/upnpd
endef

UPNP_LDFLAGS=-L$(STAGING_DIR)/usr/lib -L $(STAGING_DIR)/lib
ifeq ($(CONFIG_BE8_MODE),y)
UPNP_LDFLAGS+=-Xlinker -EB -Xlinker --be8
endif

define Build/Compile
	echo "OpenWRT/$(OPENWRTVERSION)" | tr \(\)\  _ >$(PKG_BUILD_DIR)/os.openwrt
	$(MAKE) -C $(PKG_BUILD_DIR) -f Makefile.linux \
		$(TARGET_CONFIGURE_OPTS) \
		STAGING_DIR="$(STAGING_DIR)" \
		CC="$(TARGET_CC)" \
		TARGET_OPENWRT=1 \
		CFLAGS="$(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include -I$(firstword $(wildcard $(KERNEL_BUILD_DIR)/iptables-*/include)) -DIPTABLES_143" \
		LDFLAGS="$(UPNP_LDFLAGS)" \
		LIBS="$(STAGING_DIR)/usr/lib/libip4tc.so"
endef

define Package/miniupnpd/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config $(1)/etc/hotplug.d/iface #$(1)/etc/hotplug.d/firewall
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/miniupnpd $(1)/usr/sbin/miniupnpd

ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg2926")
	$(INSTALL_CONF) ./files/upnpd_emg2926.config $(1)/etc/config/upnpd
else ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg3425vt")
	$(INSTALL_CONF) ./files/upnpd_emg3425vt.config $(1)/etc/config/upnpd
else
	$(INSTALL_CONF) ./files/upnpd.config $(1)/etc/config/upnpd
endif
	$(INSTALL_DATA) ./files/miniupnpd.hotplug $(1)/etc/hotplug.d/iface/14-miniupnpd
#	$(INSTALL_DATA) ./files/miniupnpd.firewall.hotplug $(1)/etc/hotplug.d/firewall/50-miniupnpd
	$(INSTALL_DIR) $(1)/usr/share/miniupnpd
	$(INSTALL_DIR) $(1)/sbin

ifeq ($(CONFIG_PACKAGE_project_EMG2926AAVK),y)
	$(INSTALL_BIN) ./files/act_miniupnpd_emg2926aavk $(1)/sbin/act_miniupnpd
	$(INSTALL_BIN) ./files/miniupnpd.init_emg2926aavk $(1)/etc/init.d/miniupnpd
else ifeq ($(CONFIG_PACKAGE_project_EMG3425AAYJ),y) 
	$(INSTALL_BIN) ./files/act_miniupnpd_emg3425aayj $(1)/sbin/act_miniupnpd
	$(INSTALL_BIN) ./files/miniupnpd.init_emg3425aayj $(1)/etc/init.d/miniupnpd
else
	$(INSTALL_BIN) ./files/act_miniupnpd $(1)/sbin/
	$(INSTALL_BIN) ./files/miniupnpd.init $(1)/etc/init.d/miniupnpd
endif

endef

$(eval $(call BuildPackage,miniupnpd))
