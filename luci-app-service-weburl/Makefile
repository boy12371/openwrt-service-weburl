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
  DEPENDS:=+luci-base +luci-lib-json +lsqlite3 +luci-compat
  PKGARCH:=all
endef

define Package/luci-app-service-weburl/description
  A LuCI application for managing service URLs with SQLite backend.
  Features include service management, operation logging and system configuration.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-service-weburl/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci/
	
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-service-weburl.json $(1)/usr/share/luci/menu.d/
	
	$(INSTALL_DIR) $(1)/usr/share/luci/view/service_weburl
	$(INSTALL_DATA) ./root/usr/share/luci/view/service_weburl/* $(1)/usr/share/luci/view/service_weburl/
	
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./root/etc/config/service_weburl $(1)/etc/config/
	
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/service_weburl.json $(1)/usr/share/rpcd/acl.d/
	
	$(INSTALL_DIR) $(1)/usr/share/luci/i18n
	$(INSTALL_DATA) ./po/zh_Hans/service_weburl.po $(1)/usr/share/luci/i18n/service-weburl.zh-cn.po
	
	$(INSTALL_DIR) $(1)/var/lib
	touch $(1)/var/lib/service_weburl.db
	chmod 0644 $(1)/var/lib/service_weburl.db
endef

# 添加测试目标
define Build/Test
	@echo "准备测试环境..."
	@mkdir -p $(PKG_BUILD_DIR)/tests
	@cp -r ./tests/* $(PKG_BUILD_DIR)/tests/
	@echo "运行单元测试..."
	@cd $(PKG_BUILD_DIR)/tests && lua test_service_weburl.lua
	@echo "测试完成"
endef

$(eval $(call BuildPackage,luci-app-service-weburl))