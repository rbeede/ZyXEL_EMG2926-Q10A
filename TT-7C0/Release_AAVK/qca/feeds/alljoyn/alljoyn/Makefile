include $(TOPDIR)/rules.mk

PKG_NAME:=alljoyn
PKG_BASE_VERSION:=14.06.00
PKG_PATCHLEVEL:=a
PKG_VERSION:=$(PKG_BASE_VERSION)$(PKG_PATCHLEVEL)
PKG_RELEASE:=1
PKG_MD5SUM:=b45a9ce7101cd15fc50d387959414bae
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)-src
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-src.tar.gz
PKG_SOURCE_URL:=https://allseenalliance.org/releases/alljoyn/$(PKG_BASE_VERSION)/

# SCons supports parallel builds but does not support make's jobserver
PKG_BUILD_PARALLEL:=$(if $(CONFIG_PKG_BUILD_USE_JOBSERVER),0,1)

PKG_CONFIG_DEPENDS:= \
	CONFIG_DEBUG \
	CONFIG_PACKAGE_alljoyn-c \
	CONFIG_PACKAGE_alljoyn-about \
	CONFIG_PACKAGE_alljoyn-samples

include $(INCLUDE_DIR)/package.mk

define Package/alljoyn/Default
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+libopenssl +libpthread +librt +libstdcpp
  URL:=http://www.allseenalliance.org
  MAINTAINER:=AllSeen Alliance <allseen-core@lists.allseenalliance.org>
endef

define Package/alljoyn
$(call Package/alljoyn/Default)
  TITLE:=AllJoyn Peer-to-Peer networking
  MENU:=1
endef

define Package/alljoyn/description
AllJoyn is a daemon and application framework for developing
ad hoc peer-to-peer applications.  This includes the run-time
daemon and C++ library.
endef


define Package/alljoyn-c
$(call Package/alljoyn/Default)
  TITLE:=AllJoyn Peer-to-Peer networking - C binding
  DEPENDS:=alljoyn
endef

define Package/alljoyn-c/description
AllJoyn C binding.  This provides a C library for building
AllJoyn programs in C.  This is just a C callable wrapper
to the C++ library.
endef


ALLJOYN_BINDINGS:=cpp,
ALLJOYN_SERVICES:=
ALLJOYN_BUILD_SERVICES_SAMPLES:=off

ifdef CONFIG_PACKAGE_alljoyn-c
  ALLJOYN_BINDINGS+=c,
endif

define AJServicePackage
  ifdef CONFIG_PACKAGE_alljoyn-$(1)
    ALLJOYN_SERVICES+=$(1),
  endif

  define Package/alljoyn-$(1)
  $(call Package/alljoyn/Default)
    TITLE:=AllJoyn - $(2) service library
    DEPENDS:=alljoyn $(3)
  endef

  define Package/alljoyn-$(1)/description
AllJoyn $(2) service library.
  endef

  define Package/alljoyn-$(1)/install
	$$(INSTALL_DIR) $$(1)/usr/lib
	$$(CP) $$(PKG_INSTALL_DIR)/$(1)/lib/liballjoyn_$(1).so $$(1)/usr/lib/
  endef
endef


$(eval $(call AJServicePackage,about,About,))


define Package/alljoyn-samples
$(call Package/alljoyn/Default)
  TITLE:=AllJoyn Peer-to-Peer networking - testing samples
  DEPENDS:=alljoyn \
	+PACKAGE_alljoyn-about:alljoyn-about
endef

define Package/alljoyn-samples/description
Alljoyn samples.  (This is primarily for testing.  The contents of this
package vary according which other alljoyn packages are selected.)
endef


ifeq ($(CONFIG_DEBUG),y)
  ALLJOYN_BUILD_VARIANT:=debug
else
  ALLJOYN_BUILD_VARIANT:=release
endif


PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/build/openwrt/openwrt/$(ALLJOYN_BUILD_VARIANT)/dist

TARGET_CFLAGS+=-fPIC
TARGET_CPPFLAGS+=-fPIC

ifdef CONFIG_PACKAGE_alljoyn-samples
  ifdef CONFIG_PACKAGE_alljoyn-about
    ALLJOYN_BUILD_SERVICES_SAMPLES:=on
  endif
endif

define Build/Configure/Default
# Override default to do nothing
endef

define Build/Compile
	scons -C $(PKG_BUILD_DIR) \
		$(PKG_JOBS) \
		WS=off \
		CPU=openwrt \
		OS=openwrt \
		"BINDINGS=$(ALLJOYN_BINDINGS)" \
		"SERVICES=$(ALLJOYN_SERVICES)" \
		"BUILD_SERVICES_SAMPLES=$(ALLJOYN_BUILD_SERVICES_SAMPLES)" \
		"VARIANT=$(ALLJOYN_BUILD_VARIANT)" \
		BR=off \
		ICE=off \
		POLICYDB=on \
		"TARGET_CC=$$(TARGET_CC)" \
		"TARGET_CXX=$$(TARGET_CXX)" \
		"TARGET_CFLAGS=$$(TARGET_CFLAGS)" \
		"TARGET_CPPFLAGS=$$(TARGET_CPPFLAGS)" \
		"TARGET_PATH=$$(TARGET_PATH)" \
		"TARGET_LINKFLAGS=$$(TARGET_LDFLAGS)" \
		"TARGET_LINK=$$(TARGET_CC)" \
		"TARGET_AR=$$(TARGET_AR)" \
		"TARGET_RANLIB=$$(TARGET_RANLIB)" \
		"STAGING_DIR=$$(STAGING_DIR)"
endef

define AJServiceInstallDev
  ifdef CONFIG_PACKAGE_alljoyn-$(1)
	$$(INSTALL_DIR) $(2)/usr/include/alljoyn/$(1)
	$$(CP) $$(PKG_INSTALL_DIR)/$(1)/inc/alljoyn/$(1)/*.h $(2)/usr/include/alljoyn/$(1)
	$$(CP) $$(PKG_INSTALL_DIR)/$(1)/lib/liballjoyn_$(1).a $(2)/usr/lib/
	$$(CP) $$(PKG_INSTALL_DIR)/$(1)/lib/liballjoyn_$(1).so $(2)/usr/lib/
  endif
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(INSTALL_DIR) $(1)/usr/include/alljoyn
	$(INSTALL_DIR) $(1)/usr/include/qcc
	$(INSTALL_DIR) $(1)/usr/include/qcc/posix
	$(CP) $(PKG_INSTALL_DIR)/cpp/inc/alljoyn/*.h $(1)/usr/include/alljoyn/
	$(CP) $(PKG_INSTALL_DIR)/cpp/inc/qcc/*.h $(1)/usr/include/qcc/
	$(CP) $(PKG_INSTALL_DIR)/cpp/inc/qcc/posix/*.h $(1)/usr/include/qcc/posix/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/cpp/lib/liballjoyn.a $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/cpp/lib/liballjoyn.so $(1)/usr/lib/
ifdef CONFIG_PACKAGE_alljoyn-c
	$(INSTALL_DIR) $(1)/usr/include/alljoyn_c
	$(CP) $(PKG_INSTALL_DIR)/c/inc/alljoyn_c/*.h $(1)/usr/include/alljoyn_c/
	$(CP) $(PKG_INSTALL_DIR)/c/lib/liballjoyn_c.a $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/c/lib/liballjoyn_c.so $(1)/usr/lib/
endif
$(call AJServiceInstallDev,about,$(1))
endef

define Package/alljoyn/conffiles
/etc/config/alljoyn
endef

define Package/alljoyn/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/alljoyn-daemon $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/cpp/lib/liballjoyn.so $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/alljoyn.init $(1)/etc/init.d/alljoyn
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/alljoyn.defaults $(1)/etc/uci-defaults/alljoyn
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/alljoyn.config $(1)/etc/config/alljoyn
endef

define Package/alljoyn-c/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/c/lib/liballjoyn_c.so $(1)/usr/lib/
endef



define SamplesInstall
ifdef CONFIG_PACKAGE_alljoyn-$(1)
	$$(INSTALL_BIN) $$(PKG_INSTALL_DIR)/$(1)/bin/* $(2)/usr/bin/
endif
endef

define Package/alljoyn-samples/install
	$(INSTALL_DIR) $(1)/usr/bin

ifneq ($(CONFIG_UBOOT_ZYXEL_TARGET),"emg2926")
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/advtunnel $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/aes_ccm $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/bastress $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/bastress2 $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/bbclient $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/bbjitter $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/bbjoin $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/bbservice $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/bbsig $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/bignum $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/compression $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/keystore $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/marshal $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/names $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/ns $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/rawclient $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/rawservice $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/remarshal $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/rsa $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/sessions $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/socktest $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/srp $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/cpp/bin/unpack $(1)/usr/bin/
endif

$(call SamplesInstall,about,$(1))
endef

define Package/alljoyn/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
    . /etc/uci-defaults/alljoyn
    rm -f /etc/uci-defaults/alljoyn
fi
exit 0
endef

define Package/alljoyn/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
    /etc/init.d/alljoyn stop
    /etc/init.d/alljoyn disable
    uci batch <<EOF
del_list ucitrack.@network[-1].affects=alljoyn
delete ucitrack.@alljoyn[-1]
commit ucitrack
EOF
fi
exit 0
endef


$(eval $(call BuildPackage,alljoyn))
$(eval $(call BuildPackage,alljoyn-c))
$(eval $(call BuildPackage,alljoyn-about))
$(eval $(call BuildPackage,alljoyn-samples))

