include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-service-weburl
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_PO_VERSION:=$(PKG_VERSION)-$(PKG_RELEASE)

PKG_LICENSE:=MIT
PKG_MAINTAINER:=richard <richard@sveil.com>

LUCI_TITLE:=LuCI Support for service-weburl
LUCI_DESCRIPTION:=Service WebUrl
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+libsqlite3

include $(TOPDIR)/feeds/luci/luci.mk

# Install service_weburl module files
define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/service_weburl
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luasrc/service_weburl/db.lua $(1)/usr/lib/lua/service_weburl/
endef

# call BuildPackage - OpenWrt buildroot signature