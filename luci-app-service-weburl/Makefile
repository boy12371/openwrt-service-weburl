include $(TOPDIR)/rules.mk

LUCI_TITLE:=Service WebURL Management Interface
LUCI_DEPENDS:=+luci-compat +luci-lib-ipkg +sqlite3-cli +qrencode
LUCI_PKGARCH:=all
PKG_NAME:=luci-app-service-weburl
PKG_VERSION:=1.1
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(PKG_NAME)/conffiles
/etc/config/data.db
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
    ( . /etc/uci-defaults/luci-project-weburl ) && rm -f /etc/uci-defaults/luci-project-weburl
    rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
}
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/usr/lib/lua/project-weburl
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DIR) $(1)/www/luci-static/resources/project-weburl
	
	$(INSTALL_CONF) ./root/etc/config/data.db $(1)/etc/config/data.db
	$(INSTALL_BIN) ./root/etc/uci-defaults/luci-project-weburl $(1)/etc/uci-defaults/
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-project-weburl.json $(1)/usr/share/rpcd/acl.d/
	
	$(INSTALL_DATA) ./luasrc/controller/project-weburl.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DATA) ./luasrc/model/cbi/project-weburl/*.lua $(1)/usr/lib/lua/luci/model/cbi/project-weburl/
	$(CP) ./luasrc/view/project-weburl $(1)/usr/lib/lua/luci/view/
	
	$(INSTALL_DATA) ./root/usr/lib/lua/project-weburl/db.lua $(1)/usr/lib/lua/project-weburl/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./po/zh-cn/project-weburl.po $(1)/usr/lib/lua/luci/i18n/project-weburl.zh-cn.lmo
	$(INSTALL_DATA) ./po/en/project-weburl.po $(1)/usr/lib/lua/luci/i18n/project-weburl.en.lmo
endef

$(eval $(call BuildPackage,$(PKG_NAME)))