include $(TOPDIR)/rules.mk

PKG_NAME:=jquery-flot-gant
#PKG_SOURCE_URL:=https://www.codeaurora.org/mirrored_source/quic/qsdk/
PKG_RELEASE:=1
PKG_VERSION:=0.1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-g90ec5b8.tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)-g90ec5b8
#PKG_MD5SUM:=c872c5f382055e2d4cfe053da4f0240a

PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/jquery-flot-gant
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=jQuery Flot Gant Chart Plugin
  URL:=http://jqueryui.com/
  DEPENDS:=+jquery-flot
endef

define Package/jquery-flot-gant/description
  Gant Chart plugin for jQuery flot
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/jquery-flot-gant/install
	$(INSTALL_DIR) $(1)/www/js/
	cp $(PKG_BUILD_DIR)/jquery.flot.gant.js $(1)/www/js/
endef

$(eval $(call BuildPackage,jquery-flot-gant))
