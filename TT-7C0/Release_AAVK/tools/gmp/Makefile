#
# Copyright (C) 2009-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=gmp
PKG_VERSION:=5.0.5

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
#PKG_SOURCE_URL:=@GNU/gmp/
PKG_MD5SUM:=8aef50959acec2a1ad41d144ffe0f3b5
PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

HOST_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/host-build.mk

unexport CFLAGS

HOST_CONFIGURE_ARGS += \
	--enable-static \
	--disable-shared \
	--enable-cxx \
	--enable-mpbsd

$(eval $(call HostBuild))
