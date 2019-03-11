#
# Copyright (C) 2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/NBG_460N_550N_550NH
	NAME:=Zyxel NBG 460N/550N/550NH
	PACKAGES:=kmod-rtc-pcf8563
endef

define Profile/NBG_460N_550N_550NH/Description
	Package set optimized for the Zyxel NBG 460N/550N/550NH Routers.
endef

$(eval $(call Profile,NBG_460N_550N_550NH))

define Profile/NBG6716
	NAME:=ZyXEL NBG6716
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-usb-storage
endef

define Profile/NBG6716/Description
	Package set optimized for the ZyXEL NBG6716
endef

$(eval $(call Profile,NBG6716))

define Profile/EMG2926
        NAME:=ZyXEL EMG2926
        PACKAGES:=kmod-usb-core kmod-usb2 kmod-usb-storage
endef

define Profile/EMG2926/Description
        Package set optimized for the ZyXEL EMG2926
endef

$(eval $(call Profile,EMG2926))

define Profile/NBG6616
	NAME:=ZyXEL NBG6616
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-usb-storage
endef

define Profile/NBG6616/Description
	Package set optimized for the ZyXEL NBG6616
endef

$(eval $(call Profile,NBG6616))

define Profile/NBG6815
        NAME:=ZyXEL NBG6815
        PACKAGES:=kmod-usb-core kmod-usb2 kmod-usb-storage
endef

define Profile/NBG6815/Description
        Package set optimized for the ZyXEL NBG6815
endef

$(eval $(call Profile,NBG6815))

define Profile/EMG2926OBM
        NAME:=ZyXEL EMG2926OBM
        PACKAGES:=kmod-usb-core kmod-usb2 kmod-usb-storage
endef

define Profile/EMG2926OBM/Description
        Package set optimized for the ZyXEL EMG2926OBM
endef

$(eval $(call Profile,EMG2926OBM))

define Profile/EMG2926AAVK
        NAME:=ZyXEL EMG2926AAVK
        PACKAGES:=kmod-usb-core kmod-usb2 kmod-usb-storage
endef

define Profile/EMG2926AAVK/Description
        Package set optimized for the ZyXEL EMG2926AAVK
endef

$(eval $(call Profile,EMG2926AAVK))

define Profile/EMG3425AAYJ
        NAME:=ZyXEL EMG3425AAYJ
        PACKAGES:=kmod-usb-core kmod-usb2 kmod-usb-storage
endef

define Profile/EMG3425AAYJ/Description
        Package set optimized for the ZyXEL EMG3425AAYJ
endef

$(eval $(call Profile,EMG3425AAYJ))

define Profile/EMG3425VT
        NAME:=ZyXEL EMG3425VT
        PACKAGES:=kmod-usb-core kmod-usb2 kmod-usb-storage
endef

define Profile/EMG3425VT/Description
        Package set optimized for the ZyXEL EMG3425VT
endef

$(eval $(call Profile,EMG3425VT))
