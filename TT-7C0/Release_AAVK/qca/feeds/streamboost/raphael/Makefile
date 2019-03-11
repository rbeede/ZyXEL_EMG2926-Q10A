include $(TOPDIR)/rules.mk

PKG_NAME:=raphael
PKG_VERSION:=2.1.0
PKG_RELEASE:=1

PKG_SOURCE:=v$(PKG_VERSION).tar.gz

PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

#PKG_SOURCE_URL:=https://github.com/DmitryBaranovskiy/$(PKG_NAME)/archive
#PKG_MD5SUM:=d35c17fe5db24b3d8af7c3369b663fab

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/raphael
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=JavaScript library that should simplify your work with vector graphics on the web
  URL:=http://raphaeljs.com/
endef

define Package/raphael/description
  Raphaël is a small JavaScript library that should simplify your
  work with vector graphics on the web. If you want to create your own
  specific chart or image crop and rotate widget, for example, you can
  achieve it simply and easily with this library.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/raphael/install
	$(INSTALL_DIR) $(1)/www/js/
	cp $(PKG_BUILD_DIR)/raphael-min.js $(1)/www/js/
endef

$(eval $(call BuildPackage,raphael))
