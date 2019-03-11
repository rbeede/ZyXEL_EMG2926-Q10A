include $(TOPDIR)/rules.mk

PKG_NAME:=jquery-flot-axislabels
#PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=git://github.com/xuanluo/flot-axislabels.git
PKG_BRANCH:=master
PKG_RELEASE:=1

PKG_REV:=a0d11e5
PKG_VERSION:=0.1-g$(PKG_REV)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

#PKG_SOURCE_VERSION:=$(PKG_REV)
#PKG_SOURCE_MIRROR:=none
PKG_BUILD_PARALLEL:=0

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/jquery-flot-axislabels
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=jQuery Flot Axis Labels Plugin
  URL:=http://jqueryui.com/
  DEPENDS:=+jquery-flot
endef

define Package/jquery-flot-axislabels/description
  Axis labels plugin for jQuery flot
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/jquery-flot-axislabels/install
	$(INSTALL_DIR) $(1)/www/js/
	cp $(PKG_BUILD_DIR)/jquery.flot.axislabels.js $(1)/www/js/
endef

$(eval $(call BuildPackage,jquery-flot-axislabels))
