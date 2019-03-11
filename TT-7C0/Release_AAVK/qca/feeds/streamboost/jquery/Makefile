include $(TOPDIR)/rules.mk

PKG_NAME:=jquery
PKG_VERSION:=1.7.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).min.js
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

#PKG_SOURCE_URL:=http://code.jquery.com
#PKG_MD5SUM:=b8d64d0bc142b3f670cc0611b0aebcae

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

define Package/jquery
  SECTION:=language-javascript
  CATEGORY:=Languages
  SUBMENU:=JavaScript
  TITLE:=Fast, small, and feature-rich JavaScript library
  URL:=http://jquery.com/
endef

define Package/jquery/description
  jQuery is a fast, small, and feature-rich JavaScript library. It makes
  things like HTML document traversal and manipulation, event handling,
  animation, and Ajax much simpler with an easy-to-use API that works
  across a multitude of browsers. With a combination of versatility and
  extensibility, jQuery has changed the way that millions of people write
  JavaScript.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/jquery/install
    $(INSTALL_DIR) $(1)/www/js/
	cp $(DL_DIR)/$(PKG_SOURCE) $(1)/www/js/
	cd $(1)/www/js/; ln -s $(PKG_SOURCE) jquery.min.js
endef

$(eval $(call BuildPackage,jquery))
