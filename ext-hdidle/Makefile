# call BuildPackage - OpenWrt buildroot signature

#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-hdidle
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-hdidle
  SECTION:=utils
  CATEGORY:=ROOter
  SUBMENU:=Optional Applications
  DEPENDS:=+hd-idle
  TITLE:=Add Hard Drive Idle
  PKGARCH:=all
endef

define Package/ext-hdidle/description
  Helper scripts for Hard Drive Idle
endef


define Build/Compile
endef

define Package/ext-hdidle/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,ext-hdidle))
