module("luci.controller.project-weburl", package.seeall)

function index()
    -- 检查配置文件是否存在，不存在则不注册菜单
    -- if not nixio.fs.access("/etc/config/project-weburl") then
    -- 	return
    -- end

    -- 创建主菜单项（路径：Services -> project-weburl）
	local page
	page = entry({ "admin", "services", "project-weburl" }, alias("admin", "services", "project-weburl", "client"),
		_("AliyunDrive WebDAV"), 10) -- 首页
    -- 依赖主模块
	page.dependent = true
    -- 依赖的 ACL 权限
	page.acl_depends = { "luci-app-project-weburl" }

    -- 注册子页面：客户端配置
	entry({ "admin", "services", "project-weburl", "client" }, cbi("project-weburl/client"), _("Settings"), 10).leaf = true
    -- 注册日志页面
	entry({ "admin", "services", "project-weburl", "log" }, form("project-weburl/log"), _("Log"), 30).leaf = true
    -- 注册 API 端点（无页面，仅处理请求）
	entry({ "admin", "services", "project-weburl", "status" }, call("action_status")).leaf = true -- 运行状态
	entry({ "admin", "services", "project-weburl", "logtail" }, call("action_logtail")).leaf = true -- 日志采集
	entry({ "admin", "services", "project-weburl", "qrcode" }, call("action_generate_qrcode")).leaf = true -- 生成扫码登录二维码地址和参数
	entry({ "admin", "services", "project-weburl", "query" }, call("action_query_qrcode")).leaf = true -- 查询扫码登录结果
	entry({ "admin", "services", "project-weburl", "invalidate-cache" }, call("action_invalidate_cache")).leaf = true -- 清除缓存
end

function action_status()
	local e = {}
	e.running = luci.sys.call("pidof project-weburl >/dev/null") == 0
	e.application = luci.sys.exec("project-weburl --version")
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function action_logtail()
	local fs = require "nixio.fs"
	local log_path = "/var/log/project-weburl.log"
	local e = {}
	e.running = luci.sys.call("pidof project-weburl >/dev/null") == 0
	if fs.access(log_path) then
		e.log = luci.sys.exec("tail -n 100 %s | sed 's/\\x1b\\[[0-9;]*m//g'" % log_path)
	else
		e.log = ""
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function action_generate_qrcode()
	local output = luci.sys.exec("project-weburl qr generate")
	luci.http.prepare_content("application/json")
	luci.http.write(output)
end

function action_query_qrcode()
	local data = luci.http.formvalue()
	local sid = data.sid
	local output = {}
	output.refresh_token = luci.sys.exec("project-weburl qr query --sid " .. sid)
	luci.http.prepare_content("application/json")
	luci.http.write_json(output)
end

function action_invalidate_cache()
	local e = {}
	e.ok = luci.sys.call("kill -HUP `pidof project-weburl`") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
