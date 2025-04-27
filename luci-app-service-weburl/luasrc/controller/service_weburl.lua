module("luci.controller.service_weburl", package.seeall)

function index()
    -- 检查配置文件是否存在，不存在则不注册菜单
    if not nixio.fs.access("/etc/config/service_weburl") then return end

    -- 创建主菜单项（路径：Services -> service_weburl）
    local page = entry({ "admin", "services", "service_weburl" }, alias("admin", "services", "service_weburl", "index"), _("Service WebUrl"), 10) -- 首页
    -- 依赖主模块
    page.dependent = true
    -- 依赖的 ACL 权限
    page.acl_depends = { "luci-app-service-weburl" }

    -- 注册首页页面
    entry({ "admin", "services", "service_weburl", "index" }, cbi("service_weburl/index"), _("Index"), 10).leaf = true
    -- 注册设置页面
    entry({ "admin", "services", "service_weburl", "settings" }, cbi("service_weburl/settings"), _("Settings"), 20).leaf = true
    -- 注册日志页面
    entry({ "admin", "services", "service_weburl", "log" }, form("service_weburl/log"), _("Log"), 30).leaf = true
    -- 注册 API 端点（无页面，仅处理请求）
    -- entry({ "admin", "services", "service_weburl", "status" }, call("action_status")).leaf = true -- 运行状态
    -- entry({ "admin", "services", "service_weburl", "logtail" }, call("action_logtail")).leaf = true -- 日志采集
    -- entry({ "admin", "services", "service_weburl", "invalidate-cache" }, call("action_invalidate_cache")).leaf = true -- 清除缓存
end

-- function action_status()
--     local e = {}
--     e.running = luci.sys.call("pidof service_weburl >/dev/null") == 0
--     e.application = luci.sys.exec("service_weburl --version")
--     luci.http.prepare_content("application/json")
--     luci.http.write_json(e)
-- end

-- function action_logtail()
--     local fs = require "nixio.fs"
--     local log_path = "/var/log/service_weburl.log"
--     local e = {}
--     e.running = luci.sys.call("pidof service_weburl >/dev/null") == 0
--     if fs.access(log_path) then
--         e.log = luci.sys.exec("tail -n 100 %s | sed 's/\\x1b\\[[0-9;]*m//g'" % log_path)
--     else
--         e.log = ""
--     end
--     luci.http.prepare_content("application/json")
--     luci.http.write_json(e)
-- end

-- function action_invalidate_cache()
--     local e = {}
--     e.ok = luci.sys.call("kill -HUP `pidof service_weburl`") == 0
--     luci.http.prepare_content("application/json")
--     luci.http.write_json(e)
-- end
