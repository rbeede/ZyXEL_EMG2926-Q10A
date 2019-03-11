include $(TOPDIR)/rules.mk

PKG_NAME:=flowmark
#PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=ssh://qca-git01.qualcomm.com:29418/streamboost/$(PKG_NAME).git
PKG_BRANCH:=banana
PKG_RELEASE:=1
PKG_START_ORDER:=43

include $(INCLUDE_DIR)/local-development.mk
ifeq ($(DUMP)$(PKG_VERSION),)
PKG_REV:=e2cb51d
PKG_VERSION:=ge2cb51d
endif
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_MIRROR:=none

PKG_BUILD_DEPENDS:=argp-standalone

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

# use SPACES here instead of tabs
define Package/$(PKG_NAME)
  CATEGORY:=Bigfoot
  SUBMENU:=Flow Detect
  TITLE:=StreamBoost to Conntrack interface
  DEPENDS:=+libsbdaemon +hiredis +libevent2-core +libnetfilter-conntrack +libpthread
  MAINTAINER:=Nic Costa <ncosta@qca.qualcomm.com>
endef

define Package/$(PKG_NAME)/description
Flowmark receives a 5-tuple and a flow ID and marks the appropriate conntrack entry with the flow ID.
endef

# use TABs here instead of spaces
MAKE_FLAGS += \
	LDLIBS+="-largp"

# TABS
define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DIR) $(1)/etc/appflow
	$(INSTALL_DIR) $(1)/etc/appflow/streamboost.d
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_NAME)     $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/$(PKG_NAME).init         $(1)/etc/appflow/streamboost.d/${PKG_START_ORDER}_$(PKG_NAME)
endef

# NO TABS, NO SPACES
$(eval $(call BuildPackage,$(PKG_NAME)))
