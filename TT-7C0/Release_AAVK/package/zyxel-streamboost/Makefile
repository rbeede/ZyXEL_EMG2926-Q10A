include $(TOPDIR)/rules.mk

PKG_NAME=zyxel-streamboost
PKG_VERSION=1
PKG_RELEASE=1

PKG_PRO_NAME:=$(shell grep "CONFIG_TARGET_ar71xx_generic_" $(TOPDIR)/.config |grep y |cut -d '_' -f 5 |cut -d '=' -f 1 )

$(warning test-->$(PKG_PRO_NAME))

include $(INCLUDE_DIR)/package.mk

define Package/zyxel-streamboost
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Modify streamboost configuration files for zyxel devices
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install


ifeq "$(PKG_PRO_NAME)" "NBG6716"
	$(CP) -a ./files/* $(1)/
else ifeq "$(PKG_PRO_NAME)" "EMG2926"
	$(CP) -a ./files_EMG2926/* $(1)/
else ifeq "$(PKG_PRO_NAME)" "EMG3425VT"
	$(CP) -a ./files_EMG3425VT/* $(1)/
else ifeq "$(PKG_PRO_NAME)" "NBG6815"
	$(CP) -a ./files_NBG6815/* $(1)/
else
	$(CP) -a ./files_EMG2926OBM/* $(1)/
endif



endef

$(eval $(call BuildPackage,zyxel-streamboost))
