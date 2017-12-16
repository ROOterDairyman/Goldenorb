#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-rooter45
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-rooter45
  SECTION:=utils
  CATEGORY:=ROOter
  DEPENDS:=+ext-rooter4 +wget
  TITLE:=ROOter support for 8/32meg routers
  PKGARCH:=all
endef

define Package/ext-rooter45/description
  Helper scripts to install ROOter on 8/32meg routers
endef

define Build/Compile
endef

define Package/ext-rooter45/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,ext-rooter45))
