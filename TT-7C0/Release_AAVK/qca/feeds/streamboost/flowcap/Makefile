include $(TOPDIR)/rules.mk

# Build package version from git sha-1
PKG_NAME:=flowcap
#PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=ssh://qca-git01.qualcomm.com:29418/streamboost/flowcap
PKG_BRANCH:=banana
PKG_START_ORDER:=55
PKG_RELEASE:=2

include $(INCLUDE_DIR)/local-development.mk
ifeq ($(DUMP)$(PKG_VERSION),)
PKG_REV:=f4b7567
PKG_VERSION:=gf4b7567
endif

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_MIRROR:=none

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/flowcap
  CATEGORY:=Bigfoot
  SUBMENU:=Flow Detect
  TITLE:=Monitor and handle packet captures from drflocs
  DEPENDS:=+libpcap
  MAINTAINER:=Ryan Nowakowski <rnowakow@qca.qualcomm.com>
endef

define Package/flowcap/description
Drflocs can save off packet captures.  flowcap manages those saved packet captures.
endef

MAKE_FLAGS += \
   	CFLAGS="$(TARGET_CFLAGS) -g -I$(STAGING_DIR)/usr/include" \
   	LDFLAGS="$(TARGET_LDFLAGS) -L$(STAGING_DIR)/usr/lib" \

define Package/flowcap/install
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/appflow/streamboost.d/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fsmon $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/pcap $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/handle_incoming_pcaps $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/cull_incoming_pcaps $(1)/usr/bin/
	$(INSTALL_BIN) ./files/flowcap.init $(1)/etc/appflow/streamboost.d/${PKG_START_ORDER}_${PKG_NAME}
endef

$(eval $(call BuildPackage,flowcap))

