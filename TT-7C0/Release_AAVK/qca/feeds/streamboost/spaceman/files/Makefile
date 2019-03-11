include $(TOPDIR)/rules.mk

PKG_NAME:=spaceman
PKG_START_ORDER:=51

PKG_VERSION:=0.0.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

# use SPACES here instead of tabs
define Package/spaceman
  CATEGORY:=Bigfoot
  SUBMENU:=Flow Detect
  TITLE:=Spaceman
  DEPENDS:=+ngrep +redis-cli @BUSYBOX_CONFIG_AWK
  MAINTAINER:=Mo Chen <moc@qca.qualcomm.com>
endef

define Package/spaceman/description
Dr. Spaceman classifies generic flows.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/spaceman/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DIR) $(1)/etc/appflow
	$(INSTALL_DIR) $(1)/etc/appflow/streamboost.d
	$(INSTALL_BIN) ./files/spaceman.init $(1)/etc/appflow/streamboost.d/${PKG_START_ORDER}_spaceman
	$(INSTALL_DIR) $(1)/usr
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/spaceman.awk $(1)/usr/sbin/spaceman.awk
	$(INSTALL_BIN) ./files/spaceman $(1)/usr/sbin/spaceman
endef

# NO TABS, NO SPACES
$(eval $(call BuildPackage,spaceman))
