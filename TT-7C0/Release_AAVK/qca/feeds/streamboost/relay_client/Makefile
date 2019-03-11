include $(TOPDIR)/rules.mk

# Build package version from git sha-1
PKG_NAME:=relay_client
PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=ssh://qca-git01.qualcomm.com:29418/streamboost/relay_client.git
#PKG_BRANCH:=banana
PKG_START_ORDER:=71

include $(INCLUDE_DIR)/local-development.mk
ifeq ($(DUMP)$(PKG_VERSION),)
PKG_REV:=8e4e051
PKG_VERSION:=g8e4e051
endif
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_MIRROR:=none
PKG_BUILD_DEPENDS:=argp-standalone

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

# use SPACES here instead of tabs
define Package/relay_client
  CATEGORY:=Bigfoot
  SUBMENU:=Bandwidth Control
  TITLE:=Daemon that relays local web calls for remote login.
  DEPENDS:= +jansson +libpthread +libcurl +argp-standalone
  MAINTAINER:=Jason Loveman <jloveman@qca.qualcomm.com>
endef

define Package/relay_client/description
relay_client relays the local http server through an https server relay
for remote login
endef

# use TABs here instead of spaces
define Package/relay_client/install
	$(INSTALL_DIR) $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/relay_client $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/appflow/streamboost.d/
	$(INSTALL_BIN) ./files/relay_client.init $(1)/etc/appflow/streamboost.d/${PKG_START_ORDER}_${PKG_NAME}
endef

# NO TABS, NO SPACES
$(eval $(call BuildPackage,relay_client))
