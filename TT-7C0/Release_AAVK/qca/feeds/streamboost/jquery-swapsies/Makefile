include $(TOPDIR)/rules.mk

PKG_NAME:=jquery-swapsies
PKG_VERSION:=20100709
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME).js

PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

#PKG_SOURCE_URL:=http://biostall.com/wp-content/uploads/2010/07
#PKG_MD5SUM:=72e39104b577ceeaec3ed50671221f99

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/jquery-swapsies
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=Swap and Re-Order Divs Smoothly Using jQuery
  URL:=http://biostall.com/swap-and-re-order-divs-smoothly-using-jquery-swapsie-plugin
  DEPENDS:=+jquery
endef

define Package/jquery-swapsies/description
  The requirement was to be able to swap two divs smoothly. Not just
  swap the contents of the divs in question, that was too easy, but to
  physically move the divs. One div to where the second div was positioned
  and vice versa, making the animation visible to the user to emphasise
  the movement.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/jquery-swapsies/install
    $(INSTALL_DIR) $(1)/www/js/
	cp $(DL_DIR)/$(PKG_SOURCE) $(1)/www/js/
endef

$(eval $(call BuildPackage,jquery-swapsies))
