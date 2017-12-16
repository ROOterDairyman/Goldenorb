#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-rooterlite
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-rooterlite
  SECTION:=utils
  CATEGORY:=ROOter
  DEPENDS:=+luci +luci-app-sqm +luci-app-ddns +luci-app-rootervpn +luci-app-mwan3 \
		+ext-command +luci-theme-darkmatter +kmod-sched-cake \
		+wget +ext-extra +luci \
		+nano +picocom +bwmon +luci-app-hotspot +luci-app-wol
  TITLE:=ROOter Lite support for 8meg and larger routers
  PKGARCH:=all
endef

define Package/ext-rooterlite/description
  Helper scripts to enable ROOter Lite on 8meg and larger routers
endef


define Build/Compile
endef

define Package/ext-rooterlite/install
	$(CP) ./files/* $(1)/


endef

$(eval $(call BuildPackage,ext-rooterlite))
