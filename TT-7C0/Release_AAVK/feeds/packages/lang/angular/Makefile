include $(TOPDIR)/rules.mk

PKG_NAME:=angular
#PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=git://github.com/angular/bower-angular.git
PKG_BRANCH:=master
PKG_RELEASE:=v1.2.0-rc.2

PKG_REV:=ffab5c4
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

define Package/angular
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=AngularJS web kit
  URL:=http://angularjs.org/
endef

define Package/angular/description
  AngularJS web kit
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/angular/install
	$(INSTALL_DIR) $(1)/www/js/
	cp $(PKG_BUILD_DIR)/angular.min.js $(1)/www/js/
endef

$(eval $(call BuildPackage,angular))
