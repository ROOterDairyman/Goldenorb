#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-umount
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-umount
  SECTION:=utils
  CATEGORY:=ROOter
  SUBMENU:=Basic Applications
  TITLE:=support for drive unmount
  PKGARCH:=all
endef

define Package/ext-umount/description
  Helper scripts to enable drive unmount
endef


define Build/Compile
endef

define Package/ext-umount/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,ext-umount))
