include $(TOPDIR)/rules.mk

PKG_NAME:=libnexus
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=ssh://qca-git01.qualcomm.com:29418/streamboost/nexus
PKG_BRANCH:=banana
PKG_RELEASE:=1

# override the local source mirror path since
# the source for libnexus is located within the
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

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=Bigfoot
  SUBMENU:=Utilities
  TITLE:=StreamBoost Nexus Userspace Library
endef

define Package/$(PKG_NAME)/Description
Userspace library for the StreamBoost Nexus system.
endef

define Build/Compile
	$(call Build/Compile/Default,utils)
endef

define Build/Install
	$(call Build/Install/Default,install-libs)
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/nexus
	$(CP) $(PKG_BUILD_DIR)/userspace/recorder.h $(1)/usr/include/nexus/

	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libnexus.so* $(1)/usr/lib/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libnexus.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
