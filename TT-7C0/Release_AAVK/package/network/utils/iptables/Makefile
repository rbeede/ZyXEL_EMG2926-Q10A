#
# Copyright (C) 2006-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=iptables
PKG_VERSION:=1.4.10
PKG_RELEASE:=4

PKG_MD5SUM:=f382fe693f0b59d87bd47bea65eca198
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
#PKG_SOURCE_URL:=http://www.netfilter.org/projects/iptables/files \
	ftp://ftp.be.netfilter.org/pub/netfilter/iptables/ \
	ftp://ftp.de.netfilter.org/pub/netfilter/iptables/ \
	ftp://ftp.no.netfilter.org/pub/netfilter/iptables/
PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1

ifneq ($(CONFIG_EXTERNAL_KERNEL_TREE),"")
PATCH_DIR:=
endif

include $(INCLUDE_DIR)/package.mk
ifeq ($(DUMP),)
  -include $(LINUX_DIR)/.config
  include $(INCLUDE_DIR)/netfilter.mk
  STAMP_CONFIGURED:=$(strip $(STAMP_CONFIGURED))_$(shell $(SH_FUNC) grep 'NETFILTER' $(LINUX_DIR)/.config | md5s)
endif


define Package/iptables/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Firewall
  URL:=http://netfilter.org/
endef

define Package/iptables/Module
$(call Package/iptables/Default)
  DEPENDS:=iptables $(1)
endef

define Package/iptables
$(call Package/iptables/Default)
  TITLE:=IPv4 firewall administration tool
  MENU:=1
  DEPENDS+= +kmod-ipt-core +libip4tc +libxtables
endef

define Package/iptables/description
IPv4 firewall administration tool.

 Matches:
  - icmp
  - tcp
  - udp
  - comment
  - limit
  - mac
  - multiport

 Targets:
  - ACCEPT
  - DROP
  - REJECT
  - LOG
  - TCPMSS

 Tables:
  - filter
  - mangle

endef

define Package/iptables-mod-conntrack-extra
$(call Package/iptables/Module, +kmod-ipt-conntrack-extra)
  TITLE:=Extra connection tracking extensions
endef

define Package/iptables-mod-conntrack-extra/description
Extra iptables extensions for connection tracking.

 Matches:
  - connbytes
  - connmark
  - recent
  - helper

 Targets:
  - CONNMARK

endef

define Package/iptables-mod-filter
$(call Package/iptables/Module, +kmod-ipt-filter)
  TITLE:=Content inspection extensions
endef

define Package/iptables-mod-filter/description
iptables extensions for packet content inspection.
Includes support for:

 Matches:
  - layer7
  - string

endef

define Package/iptables-mod-ipopt
$(call Package/iptables/Module, +kmod-ipt-ipopt)
  TITLE:=IP/Packet option extensions
endef

define Package/iptables-mod-ipopt/description
iptables extensions for matching/changing IP packet options.

 Matches:
  - dscp
  - ecn
  - length
  - mark
  - statistic
  - tcpmss
  - time
  - unclean
  - hl

 Targets:
  - DSCP
  - CLASSIFY
  - ECN
  - MARK
  - HL

endef

define Package/iptables-mod-ipsec
$(call Package/iptables/Module, +kmod-ipt-ipsec)
  TITLE:=IPsec extensions
endef

define Package/iptables-mod-ipsec/description
iptables extensions for matching ipsec traffic.

 Matches:
  - ah
  - esp
  - policy

endef

define Package/iptables-mod-ipset
$(call Package/iptables/Module,)
  TITLE:=IPset iptables extensions
endef

define Package/iptables-mod-ipset/description
IPset iptables extensions.

 Matches:
  - set

 Targets:
  - SET

endef

define Package/iptables-mod-nat-extra
$(call Package/iptables/Module, +kmod-ipt-nat-extra)
  TITLE:=Extra NAT extensions
endef

define Package/iptables-mod-nat-extra/description
iptables extensions for extra NAT targets.

 Targets:
  - MIRROR
  - NETMAP
  - REDIRECT
endef

define Package/iptables-mod-ulog
$(call Package/iptables/Module, +kmod-ipt-ulog)
  TITLE:=user-space packet logging
endef

define Package/iptables-mod-ulog/description
iptables extensions for user-space packet logging.

 Targets:
  - ULOG

endef

define Package/iptables-mod-hashlimit
$(call Package/iptables/Module, +kmod-ipt-hashlimit)
  TITLE:=hashlimit matching
endef

define Package/iptables-mod-hashlimit/description
iptables extensions for hashlimit matching

 Matches:
  - hashlimit

endef

define Package/iptables-mod-iprange
$(call Package/iptables/Module, +kmod-ipt-iprange)
  TITLE:=IP range extension
endef

define Package/iptables-mod-iprange/description
iptables extensions for matching ip ranges.

 Matches:
  - iprange

endef

define Package/iptables-mod-extra
$(call Package/iptables/Module, +kmod-ipt-extra)
  TITLE:=Other extra iptables extensions
endef

define Package/iptables-mod-extra/description
Other extra iptables extensions.

 Matches:
  - condition
  - owner
  - physdev (if ebtables is enabled)
  - pkttype
  - quota

endef

define Package/iptables-mod-led
$(call Package/iptables/Module, +kmod-ipt-led)
  TITLE:=LED trigger iptables extension
endef

define Package/iptables-mod-led/description
iptables extension for triggering a LED.

 Targets:
  - LED

endef

define Package/iptables-mod-tproxy
$(call Package/iptables/Module, +kmod-ipt-tproxy)
  TITLE:=Transparent proxy iptables extensions
endef

define Package/iptables-mod-tproxy/description
Transparent proxy iptables extensions.

 Matches:
  - socket

 Targets:
  - TPROXY

endef

define Package/iptables-mod-tee
$(call Package/iptables/Module, +kmod-ipt-tee)
  TITLE:=TEE iptables extensions
endef

define Package/iptables-mod-tee/description
TEE iptables extensions.

 Targets:
  - TEE

endef

define Package/iptables-mod-u32
$(call Package/iptables/Module, +kmod-ipt-u32)
  TITLE:=U32 iptables extensions
endef

define Package/iptables-mod-u32/description
U32 iptables extensions.

 Matches:
  - u32

endef

define Package/iptables-mod-webstr
$(call Package/iptables/Module, +kmod-ipt-webstr)
  TITLE:=WEBSTR extension
endef

define Package/iptables-mod-webstr/description
iptables extensions for WEBSTR.
 Includes:
  - libipt_webstr
endef

define Package/iptables-mod-porttrigger
$(call Package/iptables/Module, +kmod-ipt-porttrigger)
  TITLE:=PORTTRIGGER extension
endef

define Package/iptables-mod-porttrigger/description
iptables extensions for PORTTRIGGER.
 Includes:
  - libipt_PORTTRIGGER
endef

define Package/ip6tables
$(call Package/iptables/Default)
  DEPENDS:=+kmod-ip6tables +libip6tc +libxtables
  CATEGORY:=IPv6
  TITLE:=IPv6 firewall administration tool
  MENU:=1
endef

define Package/libiptc
$(call Package/iptables/Default)
  SECTION:=libs
  CATEGORY:=Libraries
  DEPENDS:=+libip4tc +libip6tc
  TITLE:=IPv4/IPv6 firewall - shared libiptc library (compatibility stub)
endef

define Package/libip4tc
$(call Package/iptables/Default)
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=IPv4 firewall - shared libiptc library
endef

define Package/libip6tc
$(call Package/iptables/Default)
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=IPv6 firewall - shared libiptc library
endef

define Package/libxtables
 $(call Package/iptables/Default)
 SECTION:=libs
 CATEGORY:=Libraries
 TITLE:=IPv4/IPv6 firewall - shared xtables library
endef

TARGET_CPPFLAGS := \
	-I$(PKG_BUILD_DIR)/include \
	-I$(LINUX_DIR)/user_headers/include \
	$(TARGET_CPPFLAGS)

TARGET_CFLAGS += \
	-I$(PKG_BUILD_DIR)/include \
	-I$(LINUX_DIR)/user_headers/include

CONFIGURE_ARGS += \
	--enable-shared \
	--enable-devel \
	$(if $(CONFIG_IPV6),--enable-ipv6,--disable-ipv6) \
	--with-kernel="$(LINUX_DIR)/user_headers" \
	--with-xtlibdir=/usr/lib/iptables \
	--enable-static

MAKE_FLAGS := \
	$(TARGET_CONFIGURE_OPTS) \
	COPT_FLAGS="$(TARGET_CFLAGS)" \
	KERNEL_DIR="$(LINUX_DIR)/user_headers/" PREFIX=/usr \
	KBUILD_OUTPUT="$(LINUX_DIR)" \
	BUILTIN_MODULES="$(patsubst ipt_%,%,$(patsubst xt_%,%,$(IPT_BUILTIN) $(IPT_CONNTRACK-m) $(IPT_NAT-m)))"

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(INSTALL_DIR) $(1)/usr/include/iptables
	$(INSTALL_DIR) $(1)/usr/include/net/netfilter

	# XXX: iptables header fixup, some headers are not installed by iptables anymore
	$(CP) $(PKG_BUILD_DIR)/include/net/netfilter/*.h $(1)/usr/include/net/netfilter/
	$(CP) $(PKG_BUILD_DIR)/include/iptables/*.h $(1)/usr/include/iptables/
	$(CP) $(PKG_BUILD_DIR)/include/iptables.h $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/include/libipulog $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/include/libiptc $(1)/usr/include/

	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libxtables.so* $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libip*tc.so* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/xtables.pc $(1)/usr/lib/pkgconfig/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/libiptc.pc $(1)/usr/lib/pkgconfig/
endef

define Package/iptables/install

	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface

	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) ./files/bin/firewall $(1)/sbin
	$(INSTALL_BIN) ./files/bin/firewall6 $(1)/sbin
	$(INSTALL_BIN) ./files/bin/nat $(1)/sbin
	$(INSTALL_BIN) ./files/bin/webstr_filter $(1)/sbin
	$(INSTALL_BIN) ./files/bin/portTrigger $(1)/sbin
	$(INSTALL_BIN) ./files/bin/parental_monitor $(1)/sbin
ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg2926")
	$(INSTALL_BIN) ./files/bin/sendto_emg2926.sh $(1)/sbin/sendto.sh
else ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg3425vt")
	$(INSTALL_BIN) ./files/bin/sendto_emg3425vt.sh $(1)/sbin/sendto.sh
else
	$(INSTALL_BIN) ./files/bin/sendto.sh $(1)/sbin
endif
	$(INSTALL_BIN) ./files/bin/resume.sh $(1)/sbin
ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"nbg6616")
	$(CP) ./files/bin/nat_nbg6616 $(1)/sbin/nat
endif
ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"nbg6716")
	$(CP) ./files/bin/nat_nbg6716 $(1)/sbin/nat
endif
ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg2926obm")
	$(CP) ./files/bin/nat_emg2926obm $(1)/sbin/nat
endif
ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg2926aavk")
	$(CP) ./files/bin/nat_emg2926aavk $(1)/sbin/nat
	$(CP) ./files/bin/webstr_filter_emg2926aavk $(1)/sbin/webstr_filter
else ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg3425aayj")
	$(CP) ./files/bin/nat_emg3425aayj $(1)/sbin/nat
	$(CP) ./files/bin/webstr_filter_emg3425aayj $(1)/sbin/webstr_filter
endif
	
	$(INSTALL_DIR) $(1)/etc/config
ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"nbg6616")
	$(INSTALL_DATA) ./files/firewall.config $(1)/etc/config/firewall
endif
	$(INSTALL_DATA) ./files/firewall6.config $(1)/etc/config/firewall6
	$(INSTALL_DATA) ./files/nat.config $(1)/etc/config/nat
	$(INSTALL_DATA) ./files/route.config $(1)/etc/config/route
	$(INSTALL_DATA) ./files/portTrigger.config $(1)/etc/config/portTrigger
	$(INSTALL_DATA) ./files/parental.config $(1)/etc/config/parental
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/firewall.init $(1)/etc/init.d/firewall
	$(INSTALL_BIN) ./files/firewall6.init $(1)/etc/init.d/firewall6
	$(INSTALL_BIN) ./files/firewall.user $(1)/etc/
	$(INSTALL_BIN) ./files/nat.init $(1)/etc/init.d/nat
	$(INSTALL_BIN) ./files/webstr_filter.init $(1)/etc/init.d/webstr_filter

	$(INSTALL_BIN) ./files/portTrigger.init $(1)/etc/init.d/portTrigger
ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg2926")
	$(INSTALL_BIN) ./files/parental_monitor_emg2926.init $(1)/etc/init.d/parental_monitor
else ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg3425vt")
	$(INSTALL_BIN) ./files/parental_monitor_emg3425vt.init $(1)/etc/init.d/parental_monitor
else
	$(INSTALL_BIN) ./files/parental_monitor.init $(1)/etc/init.d/parental_monitor
endif	
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DATA) ./files/firewall.awk $(1)/usr/lib
	$(INSTALL_DATA) ./files/firewall6.awk $(1)/usr/lib

	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_BUILD_DIR)/.libs/iptables-multi $(1)/usr/sbin/
	
	(cd $(1)/usr/sbin ; \
	    ln -sf iptables-multi iptables \
	)
	
	$(INSTALL_DIR) $(1)/usr/lib/iptables

	(cd $(PKG_BUILD_DIR)/extensions ; \
		for m in $(patsubst xt_%,ipt_%,$(IPT_BUILTIN)) $(patsubst ipt_%,xt_%,$(IPT_BUILTIN)); do \
			if [ -f $(PKG_BUILD_DIR)/extensions/lib$$$${m}.so ]; then \
				$(CP) $(PKG_BUILD_DIR)/extensions/lib$$$${m}.so $(1)/usr/lib/iptables/ ;\
			fi; \
		done \
	)	
	
	$(CP) $(PKG_BUILD_DIR)/extensions/libipt_PORTTRIGGER.so* $(1)/usr/lib/iptables
	$(CP) $(PKG_BUILD_DIR)/extensions/libipt_webstr.so* $(1)/usr/lib/iptables
	$(CP) $(PKG_BUILD_DIR)/extensions/libxt_recent.so* $(1)/usr/lib/iptables
	$(CP) $(PKG_BUILD_DIR)/extensions/libxt_connlimit.so* $(1)/usr/lib/iptables
	$(CP) $(PKG_BUILD_DIR)/extensions/libxt_mark.so* $(1)/usr/lib/iptables
	
	$(INSTALL_DIR) $(1)/lib/firewall

	$(INSTALL_BIN) ./files/configure_firewall6 $(1)/lib/firewall/configure_firewall6
	$(INSTALL_BIN) ./files/configure_v6filter_rules $(1)/lib/firewall/configure_v6filter_rules	

	$(INSTALL_BIN) ./files/ip6tables_app_order $(1)/lib/firewall/ip6tables_app_order

ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg2926aavk")
	$(INSTALL_DATA) ./files/iptables.hotplug_emg2926aavk $(1)/etc/hotplug.d/iface/13-iptables
	$(INSTALL_DATA) ./files/nat.hotplug_emg2926aavk $(1)/etc/hotplug.d/iface/11-nat
	$(INSTALL_BIN) ./files/firewall_guest_wlan_EMG2926aavk $(1)/lib/firewall/firewall_guest_wlan
	$(INSTALL_BIN) ./files/iptables_app_order_EMG2926aavk $(1)/lib/firewall/iptables_app_order
	$(INSTALL_BIN) ./files/configure_filter_rules_emg2926aavk $(1)/lib/firewall/configure_filter_rules
	$(INSTALL_BIN) ./files/configure_firewall_EMG2926aavk $(1)/lib/firewall/configure_firewall
	$(INSTALL_BIN) ./files/route.init_EMG2926aavk $(1)/etc/init.d/route
else ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg3425aayj")
	$(INSTALL_DATA) ./files/iptables.hotplug_emg3425aayj $(1)/etc/hotplug.d/iface/13-iptables
	$(INSTALL_DATA) ./files/nat.hotplug_emg3425aayj $(1)/etc/hotplug.d/iface/11-nat
	$(INSTALL_BIN) ./files/firewall_guest_wlan_EMG3425aayj $(1)/lib/firewall/firewall_guest_wlan
	$(INSTALL_BIN) ./files/iptables_app_order_EMG3425aayj $(1)/lib/firewall/iptables_app_order
	$(INSTALL_BIN) ./files/configure_filter_rules_emg3425aayj $(1)/lib/firewall/configure_filter_rules
	$(INSTALL_BIN) ./files/configure_firewall_EMG3425aayj $(1)/lib/firewall/configure_firewall
	$(INSTALL_BIN) ./files/route.init_EMG3425aayj $(1)/etc/init.d/route
else
	$(INSTALL_DATA) ./files/iptables.hotplug $(1)/etc/hotplug.d/iface/13-iptables
	$(INSTALL_DATA) ./files/nat.hotplug $(1)/etc/hotplug.d/iface/11-nat
	$(INSTALL_BIN) ./files/firewall_guest_wlan $(1)/lib/firewall/firewall_guest_wlan
	$(INSTALL_BIN) ./files/iptables_app_order $(1)/lib/firewall/iptables_app_order
	$(INSTALL_BIN) ./files/configure_filter_rules $(1)/lib/firewall/configure_filter_rules
	$(INSTALL_BIN) ./files/configure_firewall $(1)/lib/firewall/configure_firewall
	$(INSTALL_BIN) ./files/route.init $(1)/etc/init.d/route
endif

ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg2926")
	$(INSTALL_BIN) ./files/iptables_app_order_EMG2926 $(1)/lib/firewall/iptables_app_order
else ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg3425vt")
	$(INSTALL_BIN) ./files/iptables_app_order_EMG3425VT $(1)/lib/firewall/iptables_app_order
endif

endef

define Package/ip6tables/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/ip6tables $(1)/usr/sbin/
	$(LN) ip6tables $(1)/usr/sbin/ip6tables-save
	$(LN) ip6tables $(1)/usr/sbin/ip6tables-restore
	$(INSTALL_DIR) $(1)/usr/lib/iptables
	(cd $(PKG_INSTALL_DIR)/usr/lib/iptables ; \
		$(CP) libip6t_*.so $(1)/usr/lib/iptables/ \
	)
endef

define Package/libiptc/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libiptc.so* $(1)/usr/lib/
endef

define Package/libip4tc/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libip4tc.so* $(1)/usr/lib/
endef

define Package/libip6tc/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libip6tc.so* $(1)/usr/lib/
endef

define Package/libxtables/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libxtables.so* $(1)/usr/lib/
endef

define BuildPlugin
  define Package/$(1)/install
	$(INSTALL_DIR) $$(1)/usr/lib/iptables
	for m in $(patsubst xt_%,ipt_%,$(2)) $(patsubst ipt_%,xt_%,$(2)); do \
		if [ -f $(PKG_INSTALL_DIR)/usr/lib/iptables/lib$$$$$$$${m}.so ]; then \
			$(CP) $(PKG_INSTALL_DIR)/usr/lib/iptables/lib$$$$$$$${m}.so $$(1)/usr/lib/iptables/ ; \
		fi; \
	done
	$(3)
  endef

  $$(eval $$(call BuildPackage,$(1)))
endef

L7_INSTALL:=\
	$(INSTALL_DIR) $$(1)/etc/l7-protocols; \
	$(CP) files/l7/*.pat $$(1)/etc/l7-protocols/


$(eval $(call BuildPackage,iptables))
$(eval $(call BuildPlugin,iptables-mod-conntrack-extra,$(IPT_CONNTRACK_EXTRA-m)))
$(eval $(call BuildPlugin,iptables-mod-extra,$(IPT_EXTRA-m)))
$(eval $(call BuildPlugin,iptables-mod-filter,$(IPT_FILTER-m),$(L7_INSTALL)))
$(eval $(call BuildPlugin,iptables-mod-ipopt,$(IPT_IPOPT-m)))
$(eval $(call BuildPlugin,iptables-mod-ipsec,$(IPT_IPSEC-m)))
$(eval $(call BuildPlugin,iptables-mod-ipset,ipt_set ipt_SET))
$(eval $(call BuildPlugin,iptables-mod-nat-extra,$(IPT_NAT_EXTRA-m)))
$(eval $(call BuildPlugin,iptables-mod-iprange,$(IPT_IPRANGE-m)))
$(eval $(call BuildPlugin,iptables-mod-ulog,$(IPT_ULOG-m)))
$(eval $(call BuildPlugin,iptables-mod-hashlimit,$(IPT_HASHLIMIT-m)))
$(eval $(call BuildPlugin,iptables-mod-led,$(IPT_LED-m)))
$(eval $(call BuildPlugin,iptables-mod-tproxy,$(IPT_TPROXY-m)))
$(eval $(call BuildPlugin,iptables-mod-tee,$(IPT_TEE-m)))
$(eval $(call BuildPlugin,iptables-mod-u32,$(IPT_U32-m)))
$(eval $(call BuildPlugin,iptables-mod-webstr,$(IPT_WEBSTR-m)))
$(eval $(call BuildPlugin,iptables-mod-porttrigger,$(IPT_PORTTRIGGER-m)))
$(eval $(call BuildPackage,ip6tables))
$(eval $(call BuildPackage,libiptc))
$(eval $(call BuildPackage,libip4tc))
$(eval $(call BuildPackage,libip6tc))
$(eval $(call BuildPackage,libxtables))
