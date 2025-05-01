include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-service-weburl
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=Your Name <your.email@example.com>
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-service-weburl
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Service WebURL Management
  DEPENDS:=+luci-base +luci-lib-json +lsqlite3
  PKGARCH:=all
endef

define Package/luci-app-service-weburl/description
  A LuCI application for managing service URLs with SQLite backend.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-service-weburl/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci/
	
	$(INSTALL_DIR) $(1)/usr/share/luci
	cp -pR ./root/usr/share/luci/* $(1)/usr/share/luci/
	
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./root/etc/config/service_weburl $(1)/etc/config/service_weburl
	
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_CONF) ./root/usr/share/rpcd/acl.d/service_weburl.json $(1)/usr/share/rpcd/acl.d/
	
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_CONF) ./root/usr/share/luci/menu.d/luci-app-service-weburl.json $(1)/usr/share/luci/menu.d/
endef

$(eval $(call BuildPackage,luci-app-service-weburl))