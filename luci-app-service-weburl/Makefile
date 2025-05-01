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

define Package/$(PKG_NAME)/install
	# Create necessary directories
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/service_weburl
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/service_weburl
	$(INSTALL_DIR) $(1)/usr/lib/lua/service_weburl  # 修改这里，确保创建正确的模块目录
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	
	# Install Lua files
	$(INSTALL_DATA) ./luasrc/controller/service_weburl.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DATA) ./luasrc/model/cbi/service_weburl/*.lua $(1)/usr/lib/lua/luci/model/cbi/service_weburl/
	$(INSTALL_DATA) ./luasrc/view/service_weburl/*.htm $(1)/usr/lib/lua/luci/view/service_weburl/
	$(INSTALL_DATA) ./luasrc/service_weburl/db.lua $(1)/usr/lib/lua/service_weburl/  # 修改这里，确保 db.lua 安装到正确位置
	
	# Install config files
	$(INSTALL_CONF) ./root/etc/config/service_weburl $(1)/etc/config/
	$(INSTALL_CONF) ./root/etc/config/data.db $(1)/etc/config/
	$(INSTALL_BIN) ./root/etc/uci-defaults/luci-app-service-weburl $(1)/etc/uci-defaults/
	
	# Install ACL file
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-service-weburl.json $(1)/usr/share/rpcd/acl.d/
	
	# Install translations
	$(INSTALL_DATA) ./po/zh-cn/service_weburl.po $(1)/usr/lib/lua/luci/i18n/service_weburl.zh-cn.lmo
	$(INSTALL_DATA) ./po/zh_Hans/service_weburl.po $(1)/usr/lib/lua/luci/i18n/service_weburl.zh_Hans.lmo
endef

# call BuildPackage - OpenWrt buildroot signature