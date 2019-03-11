include $(TOPDIR)/rules.mk

PKG_NAME:=jquery-jscrollpane
PKG_VERSION:=2.0.0beta10
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_VERSION).tar.gz

#PKG_SOURCE_URL:=https://github.com/vitch/jScrollPane/archive
#PKG_MD5SUM:=a20c501421af9a4b14def93ea8737bf4

PKG_SOURCE_SUBDIR=jScrollPane-$(PKG_VERSION)

PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

PKG_BUILD_DIR=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)


include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/jquery-jscrollpane
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=jQuery plugin to skin scroll bars with CSS
  URL:=http://jscrollpane.kelvinluck.com
  DEPENDS:=+jquery
endef

define Package/jquery-jscrollpane/description
  jScrollPane is a cross-browser jQuery plugin by Kelvin Luck which
  converts a browser's default scrollbars (on elements with a relevant
  overflow property) into an HTML structure which can be easily skinned
  with CSS.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/jquery-jscrollpane/install
	$(INSTALL_DIR) $(1)/www/js/
	$(INSTALL_DIR) $(1)/www/css/
	cp $(PKG_BUILD_DIR)/script/jquery.jscrollpane.min.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/style/jquery.jscrollpane.css $(1)/www/css/
	cp $(PKG_BUILD_DIR)/themes/lozenge/style/jquery.jscrollpane.lozenge.css $(1)/www/css/
endef

$(eval $(call BuildPackage,jquery-jscrollpane))
