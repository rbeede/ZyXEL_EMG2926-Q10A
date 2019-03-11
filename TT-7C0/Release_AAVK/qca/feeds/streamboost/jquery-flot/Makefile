include $(TOPDIR)/rules.mk

PKG_NAME:=jquery-flot
PKG_VERSION:=0.8.0
PKG_RELEASE:=1

PKG_SOURCE:=flot-$(PKG_VERSION).zip
PKG_SOURCE_SUBDIR=flot
PKG_BUILD_DIR=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

#PKG_SOURCE_URL:=http://www.flotcharts.org/downloads
#PKG_MD5SUM:=b1fe8d1fe06ce2173b3ccd6ed532815d

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/jquery-flot
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=Flot is a pure JavaScript plotting library for jQuery
  URL:=http://www.flotcharts.org/
  DEPENDS:=+jquery
endef

define Package/jquery-flot/description
  Flot is a pure JavaScript plotting library for jQuery, with a focus
  on simple usage, attractive looks and interactive features.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/jquery-flot/install
	$(INSTALL_DIR) $(1)/www/js/
	cp $(PKG_BUILD_DIR)/jquery.flot.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/jquery.flot.categories.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/jquery.flot.time.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/jquery.flot.pie.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/jquery.flot.stack.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/jquery.flot.resize.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/jquery.flot.canvas.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/excanvas.min.js $(1)/www/js/
endef

$(eval $(call BuildPackage,jquery-flot))
