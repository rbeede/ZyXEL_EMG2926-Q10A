include $(TOPDIR)/rules.mk

PKG_NAME:=jquery-sparkline
PKG_VERSION:=1.4.3
PKG_RELEASE:=1

PKG_SOURCE:=jquery.sparkline.min.js
#PKG_SOURCE_URL:=http://omnipotent.net/jquery.sparkline/$(PKG_VERSION)
#PKG_MD5SUM:=62925e14d0155e4591098b223916c661

PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/jquery-sparkline
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=jQuery plugin to generate small inline charts
  URL:=http://omnipotent.net/jquery.sparkline
  DEPENDS:=+jquery
endef

define Package/jquery-sparkline/description
  This jQuery plugin generates sparklines (small inline charts) directly
  in the browser using data supplied either inline in the HTML, or
  via javascript.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/jquery-sparkline/install
    $(INSTALL_DIR) $(1)/www/js/
	cp $(DL_DIR)/$(PKG_SOURCE) $(1)/www/js/
endef

$(eval $(call BuildPackage,jquery-sparkline))
