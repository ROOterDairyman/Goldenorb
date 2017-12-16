#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-rooterbcm8
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-rooterbcm8
  SECTION:=utils
  CATEGORY:=ROOter
  DEPENDS:=+luci +luci-app-sqm +luci-app-ddns +luci-app-rootervpn +luci-app-mwan3 \
		+ext-rooter-basic +ext-p910nd +ext-samba \
		+ext-umount +ext-command +luci-theme-darkmatter +kmod-sched-cake \
		+wget +ext-extra \
		+nano +picocom +bwmon +luci-app-wol
  TITLE:=ROOter support for 8meg and larger routers using Broadcom
  PKGARCH:=all
endef

define Package/ext-rooterbcm8/description
  Helper scripts to enable ROOter on 8meg and larger routers using Broadcom
endef


define Build/Compile
endef

define Package/ext-rooterbcm8/install
	$(CP) ./files/* $(1)/


endef

$(eval $(call BuildPackage,ext-rooterbcm8))
