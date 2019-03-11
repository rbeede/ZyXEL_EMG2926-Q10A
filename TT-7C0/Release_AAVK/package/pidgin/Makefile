#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=pidgin
PKG_VERSION:=2.10.9
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
#PKG_SOURCE_URL:=@SF/$(PKG_NAME)
PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD
PKG_MD5SUM:=a0ebb55083e2dfc22a75c504acde6a07

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/nls.mk

define Package/libpurple
  SECTION:=libs
  CATEGORY:=Libraries
  DEPENDS:=+libxml2 +libgnutls +libncursesw +glib2 $(ICONV_DEPENDS) $(INTL_DEPENDS)
  TITLE:=libpurple is intended to be the core of an IM program
  URL:=http://developer.pidgin.im
endef

define Package/libpurple/description
	libpurple is intended to be the core of an IM program. When using libpurple, you'll basically be writing a UI for this core chunk of code.
endef

define Build/Configure
	$(call Build/Configure/Default, \
		--disable-gtkui \
		--disable-gstreamer \
		--disable-vv \
		--disable-idn \
		--disable-meanwhile \
		--disable-avahi \
		--disable-dbus \
		--disable-perl \
		--disable-tcl \
		--without-x \
		--enable-shared \
		--enable-static \
		--disable-gestures \
		--disable-doxygen \
		--disable-consoleui \
		--enable-debug \
		--with-gnutls-libs=$(STAGING_DIR)/usr/lib \
		--with-gnutls-includes=$(STAGING_DIR)/usr/include \
		--with-ncurses-headers=$(STAGING_DIR)/usr/include/ncursesw \
		--with-dynamic-prpls=jabber \
	)
endef

TARGET_LDFLAGS+=-Wl,-rpath-link=$(STAGING_DIR)/usr/lib -liconv

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/libpurple
	$(CP) \
		$(PKG_INSTALL_DIR)/usr/include/libpurple/* \
		$(1)/usr/include/libpurple

	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/lib/purple-2 $(1)/usr/lib/pkgconfig
	$(CP) \
		$(PKG_INSTALL_DIR)/usr/lib/libpurple.{la,a,so*} \
		$(1)/usr/lib
	$(CP) \
		$(PKG_INSTALL_DIR)/usr/lib/purple-2/* \
		$(1)/usr/lib/purple-2
	$(CP) \
		$(PKG_INSTALL_DIR)/usr/lib/pkgconfig/purple.pc \
		$(1)/usr/lib/pkgconfig

	$(INSTALL_DIR) $(1)/usr/share/aclocal
	$(INSTALL_DATA) \
		$(PKG_INSTALL_DIR)/usr/share/aclocal/purple.m4 \
		$(1)/usr/share/aclocal
endef

define Package/libpurple/install
	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/lib/purple-2
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libpurple.so* $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/autoaccept.so      $(1)/usr/lib/purple-2
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/buddynote.so       $(1)/usr/lib/purple-2
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/idle.so            $(1)/usr/lib/purple-2
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/joinpart.so        $(1)/usr/lib/purple-2
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/statenotify.so     $(1)/usr/lib/purple-2
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/log_reader.so      $(1)/usr/lib/purple-2
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/newline.so         $(1)/usr/lib/purple-2
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/offlinemsg.so      $(1)/usr/lib/purple-2
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/psychic.so         $(1)/usr/lib/purple-2
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/libjabber.so.0.0.0 $(1)/usr/lib/purple-2/libjabber.so.0
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/libxmpp.so         $(1)/usr/lib/purple-2
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/ssl.so             $(1)/usr/lib/purple-2
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/purple-2/ssl-gnutls.so      $(1)/usr/lib/purple-2
endef

$(eval $(call BuildPackage,libpurple))
