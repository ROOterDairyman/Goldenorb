#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-rooterbcm
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-rooterbcm
  SECTION:=utils
  CATEGORY:=ROOter
  DEPENDS:=+luci +luci-app-sqm +luci-app-ddns +luci-app-mwan3 \
		+ext-rooter-basic +ext-p910nd +ext-samba \
		+ext-umount +ext-command +kmod-sched-cake \
		 +wget +nano +picocom
  TITLE:=ROOter support for BRCM47xx 8meg and larger routers
  PKGARCH:=all
endef

define Package/ext-rooterbcm/description
  Helper scripts to enable ROOter on 8meg and larger routers
endef


define Build/Compile
endef

define Package/ext-rooterbcm/install
	$(CP) ./files/* $(1)/


endef

$(eval $(call BuildPackage,ext-rooterbcm))
