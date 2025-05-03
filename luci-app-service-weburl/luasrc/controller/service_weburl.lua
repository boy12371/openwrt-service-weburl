module("luci.controller.service_weburl", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/service_weburl") then return end

	local page
	page = entry({ "admin", "services", "service_weburl" }, alias("admin", "services", "service_weburl", "client"),
		_("WebURL Service"), 10) -- 首页
	page.dependent = true
	page.acl_depends = { "luci-app-service-weburl" }

	entry({ "admin", "services", "service_weburl", "client" }, cbi("service_weburl/client"), _("Settings"), 10).leaf = true -- 客户端配置
	entry({ "admin", "services", "service_weburl", "log" }, form("service_weburl/log"), _("Log"), 30).leaf = true -- 日志页面

	entry({ "admin", "services", "service_weburl", "status" }, call("action_status")).leaf = true -- 运行状态
	entry({ "admin", "services", "service_weburl", "logtail" }, call("action_logtail")).leaf = true -- 日志采集
	entry({ "admin", "services", "service_weburl", "invalidate-cache" }, call("action_invalidate_cache")).leaf = true -- 清除缓存
end

function action_status()
	local e = {}
	e.running = luci.sys.call("pidof service_weburl >/dev/null") == 0
	e.application = luci.sys.exec("service_weburl --version")
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function action_logtail()
	local fs = require "nixio.fs"
	local log_path = "/var/log/service_weburl.log"
	local e = {}
	e.running = luci.sys.call("pidof service_weburl >/dev/null") == 0
	if fs.access(log_path) then
		e.log = luci.sys.exec("tail -n 100 %s | sed 's/\\x1b\\[[0-9;]*m//g'" % log_path)
	else
		e.log = ""
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function action_invalidate_cache()
	local e = {}
	e.ok = luci.sys.call("kill -HUP `pidof service_weburl`") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end