#
# Copyright (C) 2006-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

FS_MENU:=Filesystems

define KernelPackage/fs-autofs4
  SUBMENU:=$(FS_MENU)
  TITLE:=AUTOFS4 filesystem support
  KCONFIG:=CONFIG_AUTOFS4_FS 
  FILES:=$(LINUX_DIR)/fs/autofs4/autofs4.ko
  AUTOLOAD:=$(call AutoLoad,30,autofs4)
endef

define KernelPackage/fs-autofs4/description
  Kernel module for AutoFS4 support
endef

$(eval $(call KernelPackage,fs-autofs4))


define KernelPackage/fs-btrfs
  SUBMENU:=$(FS_MENU)
  TITLE:=BTRFS filesystem support
  DEPENDS:=+kmod-lib-crc32c +kmod-lib-lzo +kmod-lib-zlib
  KCONFIG:=\
	CONFIG_BTRFS_FS \
	CONFIG_BTRFS_FS_POSIX_ACL=n \
	CONFIG_BTRFS_FS_CHECK_INTEGRITY=n
  FILES:=\
	$(LINUX_DIR)/fs/btrfs/btrfs.ko
  AUTOLOAD:=$(call AutoLoad,30,btrfs,1)
endef

define KernelPackage/fs-btrfs/description
  Kernel module for BTRFS support
endef

$(eval $(call KernelPackage,fs-btrfs))


define KernelPackage/fs-cifs
  SUBMENU:=$(FS_MENU)
  TITLE:=CIFS support
  KCONFIG:= \
	CONFIG_CIFS \
	CONFIG_CIFS_DFS_UPCALL=n \
	CONFIG_CIFS_UPCALL=n
  FILES:=$(LINUX_DIR)/fs/cifs/cifs.ko
  AUTOLOAD:=$(call AutoLoad,30,cifs)
  $(call AddDepends/nls)
  DEPENDS+= \
    +kmod-crypto-arc4 \
    +kmod-crypto-hmac \
    +kmod-crypto-md5 \
    +kmod-crypto-md4 \
    +kmod-crypto-des \
    +kmod-crypto-ecb
endef

define KernelPackage/fs-cifs/description
 Kernel module for CIFS support
endef

$(eval $(call KernelPackage,fs-cifs))


define KernelPackage/fs-exportfs
  SUBMENU:=$(FS_MENU)
  TITLE:=exportfs kernel server support
  KCONFIG:=CONFIG_EXPORTFS
  FILES=$(LINUX_DIR)/fs/exportfs/exportfs.ko
  AUTOLOAD:=$(call AutoLoad,20,exportfs)
endef

define KernelPackage/fs-exportfs/description
 Kernel module for exportfs. Needed for some other modules.
endef

$(eval $(call KernelPackage,fs-exportfs))

define KernelPackage/fs-ext3
  SUBMENU:=$(FS_MENU)
  TITLE:=EXT3 filesystem support
  KCONFIG:= \
        CONFIG_EXT3_FS \
        CONFIG_JBD
  DEPENDS:=$(if $(DUMP)$(CONFIG_FS_MBCACHE),+kmod-fs-mbcache)
  FILES:= \
        $(LINUX_DIR)/fs/ext3/ext3.$(LINUX_KMOD_SUFFIX) \
        $(LINUX_DIR)/fs/jbd/jbd.$(LINUX_KMOD_SUFFIX)
  AUTOLOAD:=$(call AutoLoad,31,jbd ext3,1)
endef

define KernelPackage/fs-ext3/description
 Kernel module for EXT3 filesystem support
endef

$(eval $(call KernelPackage,fs-ext3))

define KernelPackage/fs-ext4
  SUBMENU:=$(FS_MENU)
  TITLE:=EXT4 filesystem support
  KCONFIG:= \
	CONFIG_EXT4_FS \
	CONFIG_JBD2
  FILES:= \
	$(LINUX_DIR)/fs/ext4/ext4.ko \
	$(LINUX_DIR)/fs/jbd2/jbd2.ko \
	$(LINUX_DIR)/fs/mbcache.ko
  AUTOLOAD:=$(call AutoLoad,30,mbcache jbd2 ext4,1)
  $(call AddDepends/crc16, +!LINUX_3_3:kmod-crypto-hash)
endef

define KernelPackage/fs-ext4/description
 Kernel module for EXT4 filesystem support
endef

$(eval $(call KernelPackage,fs-ext4))


define KernelPackage/fuse
  SUBMENU:=$(FS_MENU)
  TITLE:=FUSE (Filesystem in Userspace) support
  KCONFIG:= CONFIG_FUSE_FS
  FILES:=$(LINUX_DIR)/fs/fuse/fuse.ko
  AUTOLOAD:=$(call AutoLoad,80,fuse)
endef

define KernelPackage/fuse/description
 Kernel module for userspace filesystem support
endef

$(eval $(call KernelPackage,fuse))


define KernelPackage/fs-hfs
  SUBMENU:=$(FS_MENU)
  TITLE:=HFS+ filesystem support
  KCONFIG:=CONFIG_HFS_FS
  FILES:=$(LINUX_DIR)/fs/hfs/hfs.ko
  AUTOLOAD:=$(call AutoLoad,30,hfs)
  $(call AddDepends/nls)
endef

define KernelPackage/fs-hfs/description
 Kernel module for HFS filesystem support
endef

$(eval $(call KernelPackage,fs-hfs))


define KernelPackage/fs-hfsplus
  SUBMENU:=$(FS_MENU)
  TITLE:=HFS+ filesystem support
  KCONFIG:=CONFIG_HFSPLUS_FS
  FILES:=$(LINUX_DIR)/fs/hfsplus/hfsplus.ko
  AUTOLOAD:=$(call AutoLoad,30,hfsplus)
  $(call AddDepends/nls,utf8)
endef

define KernelPackage/fs-hfsplus/description
 Kernel module for HFS+ filesystem support
endef

$(eval $(call KernelPackage,fs-hfsplus))


define KernelPackage/fs-isofs
  SUBMENU:=$(FS_MENU)
  TITLE:=ISO9660 filesystem support
  KCONFIG:=CONFIG_ISO9660_FS CONFIG_JOLIET=y CONFIG_ZISOFS=n
  FILES:=$(LINUX_DIR)/fs/isofs/isofs.ko
  AUTOLOAD:=$(call AutoLoad,30,isofs)
  $(call AddDepends/nls)
endef

define KernelPackage/fs-isofs/description
 Kernel module for ISO9660 filesystem support
endef

$(eval $(call KernelPackage,fs-isofs))


define KernelPackage/fs-minix
  SUBMENU:=$(FS_MENU)
  TITLE:=Minix filesystem support
  KCONFIG:=CONFIG_MINIX_FS
  FILES:=$(LINUX_DIR)/fs/minix/minix.ko
  AUTOLOAD:=$(call AutoLoad,30,minix)
endef

define KernelPackage/fs-minix/description
 Kernel module for Minix filesystem support
endef

$(eval $(call KernelPackage,fs-minix))


define KernelPackage/fs-msdos
  SUBMENU:=$(FS_MENU)
  TITLE:=MSDOS filesystem support
  KCONFIG:=CONFIG_MSDOS_FS
  FILES:=$(LINUX_DIR)/fs/fat/msdos.ko
  AUTOLOAD:=$(call AutoLoad,40,msdos)
  $(call AddDepends/nls)
endef

define KernelPackage/fs-msdos/description
 Kernel module for MSDOS filesystem support
endef

$(eval $(call KernelPackage,fs-msdos))


define KernelPackage/fs-nfs
  SUBMENU:=$(FS_MENU)
  TITLE:=NFS filesystem support
  DEPENDS:=+kmod-fs-nfs-common
  KCONFIG:= \
	CONFIG_NFS_FS \
	CONFIG_NFS_USE_LEGACY_DNS=n \
	CONFIG_NFS_USE_NEW_IDMAPPER=n
  FILES:= \
	$(LINUX_DIR)/fs/nfs/nfs.ko
  AUTOLOAD:=$(call AutoLoad,40,nfs)
endef

define KernelPackage/fs-nfs/description
 Kernel module for NFS support
endef

$(eval $(call KernelPackage,fs-nfs))


define KernelPackage/fs-nfs-common
  SUBMENU:=$(FS_MENU)
  TITLE:=Common NFS filesystem modules
  KCONFIG:= \
	CONFIG_LOCKD \
	CONFIG_SUNRPC
  FILES:= \
	$(LINUX_DIR)/fs/lockd/lockd.ko \
	$(LINUX_DIR)/net/sunrpc/sunrpc.ko
  AUTOLOAD:=$(call AutoLoad,30,sunrpc lockd)
endef

$(eval $(call KernelPackage,fs-nfs-common))


define KernelPackage/fs-nfs-common-v4
  SUBMENU:=$(FS_MENU)
  TITLE:=Common NFS V4 filesystem modules
  KCONFIG+=\
	CONFIG_SUNRPC_GSS\
	CONFIG_NFS_V4=y\
	CONFIG_NFSD_V4=y
  DEPENDS:= @BROKEN
  FILES+=$(LINUX_DIR)/net/sunrpc/auth_gss/auth_rpcgss.ko
  AUTOLOAD=$(call AutoLoad,30,auth_rpcgss)
endef

define KernelPackage/fs-nfs-common-v4/description
 Kernel modules for NFS V4 & NFSD V4 kernel support
endef

$(eval $(call KernelPackage,fs-nfs-common-v4))


define KernelPackage/fs-nfsd
  SUBMENU:=$(FS_MENU)
  TITLE:=NFS kernel server support
  DEPENDS:=+kmod-fs-nfs-common +kmod-fs-exportfs
  KCONFIG:= \
	CONFIG_NFSD \
	CONFIG_NFSD_FAULT_INJECTION=n
  FILES:=$(LINUX_DIR)/fs/nfsd/nfsd.ko
  AUTOLOAD:=$(call AutoLoad,40,nfsd)
endef

define KernelPackage/fs-nfsd/description
 Kernel module for NFS kernel server support
endef

$(eval $(call KernelPackage,fs-nfsd))


define KernelPackage/fs-ntfs
  SUBMENU:=$(FS_MENU)
  TITLE:=NTFS filesystem support
  KCONFIG:=CONFIG_NTFS_FS
  FILES:=$(LINUX_DIR)/fs/ntfs/ntfs.ko
  AUTOLOAD:=$(call AutoLoad,30,ntfs)
  $(call AddDepends/nls)
endef

define KernelPackage/fs-ntfs/description
 Kernel module for NTFS filesystem support
endef

$(eval $(call KernelPackage,fs-ntfs))


define KernelPackage/fs-reiserfs
  SUBMENU:=$(FS_MENU)
  TITLE:=ReiserFS filesystem support
  KCONFIG:=CONFIG_REISERFS_FS
  FILES:=$(LINUX_DIR)/fs/reiserfs/reiserfs.ko
  AUTOLOAD:=$(call AutoLoad,30,reiserfs,1)
endef

define KernelPackage/fs-reiserfs/description
 Kernel module for ReiserFS support
endef

$(eval $(call KernelPackage,fs-reiserfs))


define KernelPackage/fs-udf
  SUBMENU:=$(FS_MENU)
  TITLE:=UDF filesystem support
  KCONFIG:=CONFIG_UDF_FS
  FILES:=$(LINUX_DIR)/fs/udf/udf.ko
  AUTOLOAD:=$(call AutoLoad,30,udf)
  DEPENDS:=+kmod-lib-crc-itu-t
  $(call AddDepends/nls)
endef

define KernelPackage/fs-udf/description
 Kernel module for UDF filesystem support
endef

$(eval $(call KernelPackage,fs-udf))


define KernelPackage/fs-vfat
  SUBMENU:=$(FS_MENU)
  TITLE:=VFAT filesystem support
  KCONFIG:= \
	CONFIG_FAT_FS \
	CONFIG_VFAT_FS
  FILES:= \
	$(LINUX_DIR)/fs/fat/fat.ko \
	$(LINUX_DIR)/fs/fat/vfat.ko
  AUTOLOAD:=$(call AutoLoad,30,fat vfat)
  $(call AddDepends/nls)
endef

define KernelPackage/fs-vfat/description
 Kernel module for VFAT filesystem support
endef

$(eval $(call KernelPackage,fs-vfat))


define KernelPackage/fs-xfs
  SUBMENU:=$(FS_MENU)
  TITLE:=XFS filesystem support
  KCONFIG:=CONFIG_XFS_FS
  DEPENDS:= +kmod-fs-exportfs @!avr32
  FILES:=$(LINUX_DIR)/fs/xfs/xfs.ko
  AUTOLOAD:=$(call AutoLoad,30,xfs,1)
endef

define KernelPackage/fs-xfs/description
 Kernel module for XFS support
endef

$(eval $(call KernelPackage,fs-xfs))
