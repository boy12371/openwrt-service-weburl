include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-project-weburl
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_PO_VERSION:=$(PKG_VERSION)-$(PKG_RELEASE)

PKG_LICENSE:=MIT
PKG_MAINTAINER:=richard <richard@sveil.com>

LUCI_TITLE:=LuCI Support for project-weburl
LUCI_DESCRIPTION:=Project WebUrl
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+luci-base

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
