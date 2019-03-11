include $(TOPDIR)/rules.mk

PKG_NAME:=angular-translate
#PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=git://github.com/PascalPrecht/bower-angular-translate.git
PKG_BRANCH:=master
PKG_RELEASE:=v1.1.0

PKG_REV:=5969f29
PKG_VERSION:=0.1-g$(PKG_REV)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_MIRROR:=none
PKG_BUILD_PARALLEL:=0

PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/angular-translate
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=Angular-Route
  URL:=http://angularjs.org/
  DEPENDS:=+angular
endef

define Package/angular-translate/description
 Angular URL Routing mechanism.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/angular-translate/install
	$(INSTALL_DIR) $(1)/www/js/
	cp $(PKG_BUILD_DIR)/angular-translate.min.js $(1)/www/js/
endef

$(eval $(call BuildPackage,angular-translate))
