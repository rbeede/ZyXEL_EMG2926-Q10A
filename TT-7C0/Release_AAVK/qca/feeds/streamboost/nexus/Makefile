include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=nexus
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=ssh://qca-git01.qualcomm.com:29418/streamboost/$(PKG_NAME)
PKG_BRANCH:=banana
PKG_RELEASE:=1

include $(INCLUDE_DIR)/local-development.mk
ifeq ($(DUMP)$(PKG_VERSION),)
PKG_REV:=c34e62a
PKG_VERSION:=gc34e62a
endif

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)

include $(INCLUDE_DIR)/package.mk

define KernelPackage/$(PKG_NAME)
  CATEGORY:=Bigfoot
  SUBMENU:=Flow Detect
  DEPENDS:=
  KCONFIG:= \
  	CONFIG_NETFILTER=y \
  	CONFIG_NETFILTER_NETLINK=y \
  	CONFIG_NF_CONNTRACK_EVENTS=y \
	CONFIG_NF_CONNTRACK_CHAIN_EVENTS=y
  TITLE:=StreamBoost Nexus
  FILES:=$(PKG_BUILD_DIR)/nexus.ko
endef

define KernelPackage/$(PKG_NAME)-example-sensor
  CATEGORY:=Bigfoot
  SUBMENU:=Flow Detect
  DEPENDS:=+kmod-nexus
  TITLE:=Example sensor StreamBoost Nexus
  FILES:=$(PKG_BUILD_DIR)/sensors/nexus_example_sensor.ko
endef

define KernelPackage/$(PKG_NAME)/Description
Nexus is the core kernel component for StreamBoost.
endef

define KernelPackage/$(PKG_NAME)-example-sensor/Description
Example sensor for the StreamBoost Nexus system.
endef

define Build/Compile/$(PKG_NAME)
	$(MAKE) -C "$(LINUX_DIR)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		ARCH="$(LINUX_KARCH)" \
		SUBDIRS="$(PKG_BUILD_DIR)" \
		EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
		modules
endef

define Build/Compile/$(PKG_NAME)-example-sensor
	$(call Build/InstallDev/$(PKG_NAME),$(STAGING_DIR))
	$(MAKE) -C "$(LINUX_DIR)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		ARCH="$(LINUX_KARCH)" \
		SUBDIRS="$(PKG_BUILD_DIR)/sensors" \
		EXTRA_CFLAGS="$(EXTRA_CFLAGS) -I$(STAGING_DIR)/usr/include" \
		modules
endef

define Build/Compile
	$(call Build/Compile/$(PKG_NAME))
	$(if $(CONFIG_PACKAGE_kmod-$(PKG_NAME)-example-sensor), \
		$(call Build/Compile/$(PKG_NAME)-example-sensor))
endef

define Build/InstallDev/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/usr/include/nexus
	$(CP) $(PKG_BUILD_DIR)/nexus.h $(1)/usr/include/nexus/
	$(CP) $(PKG_BUILD_DIR)/packet.h $(1)/usr/include/nexus/
	$(CP) $(PKG_BUILD_DIR)/tuple.h $(1)/usr/include/nexus/
	$(CP) $(PKG_BUILD_DIR)/compat.h $(1)/usr/include/nexus/
endef

define Build/InstallDev
	$(call Build/InstallDev/$(PKG_NAME),$(1),$(2))
endef

$(eval $(call KernelPackage,$(PKG_NAME)))
$(eval $(call KernelPackage,$(PKG_NAME)-example-sensor))
