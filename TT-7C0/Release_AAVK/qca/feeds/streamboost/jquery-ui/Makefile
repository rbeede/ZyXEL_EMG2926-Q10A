include $(TOPDIR)/rules.mk

PKG_NAME:=jquery-ui
#PKG_SOURCE_URL:=https://www.codeaurora.org/mirrored_source/quic/qsdk/
PKG_RELEASE:=1
PKG_VERSION:=1.8.21

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-gde5bb86.tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)-gde5bb86
#PKG_MD5SUM:=4174ef7dce206992753b80868a01485a

PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/jquery-ui
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=jQuery User Interface
  URL:=http://jqueryui.com/
  DEPENDS:=+jquery
endef

define Package/jquery-ui/description
  jQuery UI is a curated set of user interface interactions,
  effects, widgets, and themes built on top of the jQuery JavaScript
  Library. Whether you're building highly interactive web applications
  or you just need to add a date picker to a form control, jQuery UI is
  the perfect choice.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/jquery-ui/install
	$(INSTALL_DIR) $(1)/www/js/
	$(INSTALL_DIR) $(1)/www/css/
	$(INSTALL_DIR) $(1)/www/css/custom-theme/
	$(INSTALL_DIR) $(1)/www/css/custom-theme/images/
	cp $(PKG_BUILD_DIR)/js/jquery-ui-1.8.21.custom.min.js $(1)/www/js/
	cp $(PKG_BUILD_DIR)/css/jquery-ui-1.8.7.css $(1)/www/css/
	cp $(PKG_BUILD_DIR)/css/custom-theme/jquery-ui-1.8.21.custom.css $(1)/www/css/custom-theme/
	cp $(PKG_BUILD_DIR)/css/custom-theme/images/* $(1)/www/css/custom-theme/images/
endef

$(eval $(call BuildPackage,jquery-ui))
