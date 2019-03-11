#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dnsmasq
PKG_VERSION:=2.67
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://thekelleys.org.uk/dnsmasq
#PKG_MD5SUM:=
PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=COPYING

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

PKG_PRO_NAME:=$(shell grep "CONFIG_PACKAGE_project_" $(TOPDIR)/.config |grep y |cut -d '_' -f 4 |cut -d '=' -f 1 )

PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1

ifeq "$(CONFIG_PACKAGE_swmp)" "y"
	PATCH_DIR:=patches
else
	PATCH_DIR:=patches
endif

include $(INCLUDE_DIR)/package.mk

define Package/dnsmasq/Default
  SECTION:=net
  CATEGORY:=Base system
  TITLE:=A lightweight DNS and DHCP server

ifeq "$(PKG_PRO_NAME)" "EMG2926"
  DEPENDS:=TARGET_ar71xx_generic_EMG2926:swmp	
endif

ifeq "$(PKG_PRO_NAME)" "EMG3425VT"
  DEPENDS:=TARGET_ar71xx_generic_EMG3425VT:swmp	
endif

ifeq "$(PKG_PRO_NAME)" "EMG2926OBM"
  DEPENDS:=TARGET_ar71xx_generic_EMG2926OBM:swmp
endif

ifeq "$(PKG_PRO_NAME)" "EMG2926AAVK"
  DEPENDS:=TARGET_ar71xx_generic_EMG2926AAVK:swmp
endif

ifeq "$(PKG_PRO_NAME)" "EMG3425AAYJ"
  DEPENDS:=TARGET_ar71xx_generic_EMG3425AAYJ:swmp
endif

  URL:=http://www.thekelleys.org.uk/dnsmasq/
endef

define Package/dnsmasq
$(call Package/dnsmasq/Default)
  VARIANT:=nodhcpv6
endef

define Package/dnsmasq-dhcpv6
$(call Package/dnsmasq/Default)
  TITLE += (with DHCPv6 support)
  DEPENDS:=@IPV6 +kmod-ipv6
  VARIANT:=dhcpv6
endef

define Package/dnsmasq/description
  It is intended to provide coupled DNS and DHCP service to a LAN.
endef

define Package/dnsmasq-dhcpv6/description
$(call Package/dnsmasq/description)

This is a variant with DHCPv6 support
endef

define Package/dnsmasq/conffiles
/etc/config/dhcp
/etc/dnsmasq.conf
endef

Package/dnsmasq-dhcpv6/conffiles = $(Package/dnsmasq/conffiles)

ZYXEL_INCDIR := -I$(BUILD_DIR)/swmp/include 

ZYXEL_LIBDIR := -L$(BUILD_DIR)/swmp/libs 

TARGET_CFLAGS += \
	-ffunction-sections -fdata-sections \
	$(if $(CONFIG_IPV6),,-DNO_IPV6) -DNO_IPSET -DNO_AUTH

ifeq ($(BUILD_VARIANT),nodhcpv6)
  TARGET_CFLAGS += -DNO_DHCP6
endif

ifeq ($(CONFIG_PACKAGE_zyxel_multiwan),y)
  TARGET_CFLAGS += -DZYXEL_OPTION60
endif

ifeq ($(CONFIG_PACKAGE_project_EMG2926),y)
        init_script="dnsmasq_no_cache.init"
else  ifeq ($(CONFIG_PACKAGE_project_EMG3425VT),y)
        init_script="dnsmasq_no_cache.init"
else  ifeq ($(CONFIG_PACKAGE_project_EMG2926AAVK),y)
        init_script="dnsmasq.init_EMG2926aavk"
else  ifeq ($(CONFIG_PACKAGE_project_EMG3425AAYJ),y)
        init_script="dnsmasq.init_EMG3425aayj"
else
	init_script="dnsmasq.init"
endif

MAKE_FLAGS := \
	$(TARGET_CONFIGURE_OPTS) \
	CFLAGS="$(TARGET_CFLAGS) $(ZYXEL_INCDIR)" \
	LDFLAGS="-Wl,--gc-sections $(ZYXEL_LIBDIR)" \
	PREFIX="/usr"

define Package/dnsmasq/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/dnsmasq $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/config
ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg2926")
	$(INSTALL_DATA) ./files/dhcp_emg2926.conf $(1)/etc/config/dhcp
else  ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg3425vt")
	$(INSTALL_DATA) ./files/dhcp_emg3425vt.conf $(1)/etc/config/dhcp
else
	$(INSTALL_DATA) ./files/dhcp.conf $(1)/etc/config/dhcp
endif	
	$(INSTALL_DATA) ./files/dnsmasq.conf $(1)/etc/dnsmasq.conf
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/$(init_script) $(1)/etc/init.d/dnsmasq
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DATA) ./files/dnsmasq.hotplug $(1)/etc/hotplug.d/iface/13-dnsmasq
endef

Package/dnsmasq-dhcpv6/install = $(Package/dnsmasq/install)

$(eval $(call BuildPackage,dnsmasq))
$(eval $(call BuildPackage,dnsmasq-dhcpv6))
