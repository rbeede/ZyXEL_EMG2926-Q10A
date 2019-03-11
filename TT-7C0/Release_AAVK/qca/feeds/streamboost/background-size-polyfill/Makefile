include $(TOPDIR)/rules.mk

PKG_NAME:=background-size-polyfill
PKG_REV:=ef5fa68
PKG_VERSION:=20121123-gef5fa68
PKG_RELEASE:=1

PKG_SOURCE:=backgroundsize.min.htc
PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

#PKG_SOURCE_URL:=https://raw.github.com/louisremi/background-size-polyfill/$(PKG_REV)
#PKG_MD5SUM:=3d3776f7216b0e72642b4dab8a2dc9e9

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/background-size-polyfill
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=Add support for background-size to IE8.
  URL:=https://github.com/louisremi/background-size-polyfill
endef

define Package/background-size-polyfill/description
  An IE behavior adding support for background-size: cover; and
  background-size: contain; to IE8.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/background-size-polyfill/install
    $(INSTALL_DIR) $(1)/www/js/
	cp $(DL_DIR)/$(PKG_SOURCE) $(1)/www/js/
endef

$(eval $(call BuildPackage,background-size-polyfill))
