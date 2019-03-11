#
# Based on include/package-ipkg.mk
#
# Copyright (c) 2013 Qualcomm Atheros, Inc.
# Copyright (C) 2006,2007 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

ifeq ($(DUMP),)
  define BuildTarget/ipkg-prebuilt
    ifeq ($(PKG_FORCE_PREBUILT)$(wildcard $(PREBUILT_DIR)/$(1)_$(VERSION)_$(PKGARCH).ipk),)
      $(BuildTarget/ipkg)
    else
      PKG_$(1):=$(1)_$(VERSION)_$(PKGARCH).ipk
      PRE_$(1):=$(PREBUILT_DIR)/$$(PKG_$(1))
      IPKG_$(1):=$(PACKAGE_DIR)/$$(PKG_$(1))

      Build/InstallDev:=

ifeq ($(BUILD_VARIANT),$$(if $$(VARIANT),$$(VARIANT),$(BUILD_VARIANT)))
        ifdef Package/$(1)/install
          ifneq ($(CONFIG_PACKAGE_$(1))$(SDK)$(DEVELOPER),)
            compile: $$(IPKG_$(1))

          ifeq ($(CONFIG_PACKAGE_$(1)),y)
          .PHONY: $(PKG_INSTALL_STAMP).$(1)
          compile: $(PKG_INSTALL_STAMP).$(1)
          $(PKG_INSTALL_STAMP).$(1):
			if [ -f $(PKG_INSTALL_STAMP).clean ]; then \
				rm -f \
					$(PKG_INSTALL_STAMP) \
					$(PKG_INSTALL_STAMP).clean; \
			fi; \
			echo "$(1)" >> $(PKG_INSTALL_STAMP)
        endif
          else
            compile: $(1)-disabled
            $(1)-disabled:
		@echo "WARNING: skipping $(1) -- package not selected"
          endif
        endif
      endif

      $$(IPKG_$(1)):
	$(CP) $$(PRE_$(1)) $$@

      $(1)-clean:
	rm -f $(PACKAGE_DIR)/$(1)_*

      clean: $(1)-clean
    endif
  endef
endif
