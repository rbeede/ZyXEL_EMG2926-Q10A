include $(TOPDIR)/rules.mk

PKG_TARGETS:=ipkg-prebuilt
PKG_NAME:=libsbdaemon
#PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=ssh://qca-git01.qualcomm.com:29418/streamboost/libsbdaemon.git
PKG_BRANCH:=banana
PKG_RELEASE:=2

include $(INCLUDE_DIR)/local-development.mk
ifeq ($(DUMP)$(PKG_VERSION),)
PKG_REV:=3680ccd
PKG_VERSION:=g3680ccd
endif
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_MIRROR:=none
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/libsbdaemon/Default
  SECTION:=Bigfoot
  CATEGORY:=Bigfoot
  SUBMENU:=Utilities
  TITLE:=Daemonizing Library
  MAINTAINER:=Mo Chen <moc@qca.qualcomm.com>
endef

define Package/libsbdaemon
$(call Package/libsbdaemon/Default)
  VARIANT:=prod
endef

define Package/libsbdaemon-rtll
$(call Package/libsbdaemon/Default)
  VARIANT:=rtll
endef

define Package/libsbdaemon/description
 This package contains a library for decrypting Streamboost daemon configuration files.  Logging level is compiled to INFO.
endef

define Package/libsbdaemon-rtll/description
 This package contains a library for decrypting Streamboost daemon configuration files.  Logging level is configurable at run-time.
endef

ifeq ($(BUILD_VARIANT),rtll)
	SBLOG_H:=sb_log_runtime.h
else
	SBLOG_H:=sb_log_minimal.h
endif

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libsbdaemon.so* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/daemonize.h $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/sb_list.h $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/sb_limits.h $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/sb_util.h $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/$(SBLOG_H) $(1)/usr/include/sb_log.h
endef

define Package/libsbdaemon/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libsbdaemon.so* $(1)/usr/lib/
endef

Package/libsbdaemon-rtll/install = $(Package/libsbdaemon/install)

$(eval $(call BuildPackage,libsbdaemon))
$(eval $(call BuildPackage,libsbdaemon-rtll))
