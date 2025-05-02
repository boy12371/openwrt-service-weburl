include $(TOPDIR)/rules.mk

LUCI_TITLE:=Service WebURL Management Interface
LUCI_DEPENDS:=+luci-compat +luci-lib-ipkg +sqlite3-cli
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

$(eval $(call BuildPackage,$(PKG_NAME)))