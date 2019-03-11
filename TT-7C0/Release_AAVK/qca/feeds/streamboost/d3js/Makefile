include $(TOPDIR)/rules.mk

PKG_NAME:=d3js
PKG_VERSION:=3.1.6
PKG_RELEASE:=2

PKG_SOURCE:=v$(PKG_VERSION).tar.gz

PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

PKG_BUILD_DIR=$(BUILD_DIR)/d3-$(PKG_VERSION)

#PKG_SOURCE_URL:=http://github.com/mbostock/d3/archive
#PKG_MD5SUM:=8b9e63261f56fa42794ce8bfd3be1be8

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/d3js
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=JavaScript library for manipulating documents based on data
  URL:=http://d3js.org/
endef

define Package/d3js/description
  D3.js is a JavaScript library for manipulating documents based on
  data. D3 helps you bring data to life using HTML, SVG and CSS. D3’s
  emphasis on web standards gives you the full capabilities of modern
  browsers without tying yourself to a proprietary framework, combining
  powerful visualization components and a data-driven approach to DOM
  manipulation
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/d3js/install
	$(INSTALL_DIR) $(1)/www/js/
	cp $(PKG_BUILD_DIR)/d3.min.js $(1)/www/js/
	cd $(1)/www/js/; ln -s d3.min.js d3.v3.min.js
endef

$(eval $(call BuildPackage,d3js))
