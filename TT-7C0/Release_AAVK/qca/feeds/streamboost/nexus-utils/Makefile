include $(TOPDIR)/rules.mk

PKG_NAME:=nexus-utils
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=ssh://qca-git01.qualcomm.com:29418/streamboost/nexus
PKG_BRANCH:=banana
PKG_RELEASE:=1

# override the local source mirror path since
# the source for nexus-utils is located within the
# nexus repo.
LOCAL_SRC:=$(TOPDIR)/qca/src/nexus
include $(INCLUDE_DIR)/local-development.mk
ifeq ($(DUMP)$(PKG_VERSION),)
PKG_REV:=c34e62a
PKG_VERSION:=gc34e62a
endif

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=Bigfoot
  SUBMENU:=Utilities
  TITLE:=StreamBoost Nexus Userspace Utilities
endef

define Package/$(PKG_NAME)/Description
Userspace utilities for the StreamBoost Nexus system.
endef

# https://forum.openwrt.org/viewtopic.php?id=21953
TARGET_LDFLAGS += -Wl,-rpath-link=$(STAGING_DIR)/usr/lib

MAKE_FLAGS += \
	EXTRA_CFLAGS="$(TARGET_CFLAGS) \
			-I$(STAGING_DIR)/usr/include" \
	EXTRA_LDFLAGS="$(TARGET_LDFLAGS) -L$(STAGING_DIR)/usr/lib"

define Build/Compile
	$(call Build/Compile/Default,utils)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/appflow/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/userspace/nxlog $(1)/etc/appflow/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
