include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/package.mk

PKG_NAME:=streamboost
PKG_RELEASE:=1
PKG_VERSION:=2.0

COMMON_PKGS += +app-flow-scripts +bwestd +callhomeclient +customer-keys
COMMON_PKGS += +wopr-db +drflocs +aperture-noauto
COMMON_PKGS += +smoketest +luci-app-streamboost +p0f-db
COMMON_PKGS += +luci-theme-steelblue +flux +tresbar +streamboost-misc
COMMON_PKGS += +opkg-curl +flowmark +qdiscman +flowman +blockman
COMMON_PKGS += +nodedetectd +overlord +sbnamed +cape
COMMON_PKGS += +redis-server +redis-cli +policy-redis +policy-reader
COMMON_PKGS += +sbnoded +sbmacouid +jigglyp0f +p0f +sea +settings-loader +sbsaved
COMMON_PKGS += +dumpevents

define Package/$(PKG_NAME)
  CATEGORY:=Bigfoot
  TITLE:=Streamboost configuration and master package
  DEPENDS:=+ozker $(COMMON_PKGS) @TARGET_ar71xx
  MAINTAINER:=Matthew McClintock <mmcclint@qca.qualcomm.com>
endef

define Package/$(PKG_NAME)/description
Contains customer specific configuration files, and also
dependencies for all other Streamboost packages
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
        $(CP) -a ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
