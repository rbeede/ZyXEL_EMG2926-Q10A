include $(TOPDIR)/rules.mk

PKG_NAME:=urijs
#PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=git://github.com/medialize/URI.js.git
PKG_BRANCH:=master
PKG_RELEASE:=v3.0.0

PKG_REV:=2bdf950
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

define Package/urijs
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=URI.js
  URL:=http://medialize.github.io/URI.js/
endef

define Package/urijs/description
 URI.js is a javascript library for working with URLs.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/urijs/install
	$(INSTALL_DIR) $(1)/www/js/
	cp $(PKG_BUILD_DIR)/src/URI.min.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/src/IPv6.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/src/SecondLevelDomains.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/src/URI.fragmentQuery.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/src/URI.fragmentURI.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/src/URITemplate.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/src/jquery.URI.min.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/src/punycode.js $(1)/www/js/
endef

$(eval $(call BuildPackage,urijs))
