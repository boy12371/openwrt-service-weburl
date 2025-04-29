module("luci.controller.service_weburl", package.seeall)

function index()
    -- 检查配置文件是否存在，不存在则不注册菜单
    if not nixio.fs.access("/etc/config/service_weburl") then return end

    -- 创建主菜单项（路径：Services -> service_weburl）
    local page = entry({ "admin", "services", "service_weburl" }, alias("admin", "services", "service_weburl", "index"), _("Service WebUrl"), 60)
    -- 依赖主模块
    page.dependent = true
    -- 依赖的 ACL 权限
    page.acl_depends = { "luci-app-service-weburl" }

    -- 注册首页服务列表页面
    entry({ "admin", "services", "service_weburl", "index" }, cbi("service_weburl/index"), _("Service Index"), 10).leaf = true
    -- 注册设置服务页面
    entry({ "admin", "services", "service_weburl", "settings" }, cbi("service_weburl/settings"), _("Application Settings"), 20).leaf = true
    entry({ "admin", "services", "service_weburl", "add" }, cbi("service_weburl/add"), _("Add Service"), 30).leaf = true
    -- 注册日志页面
    entry({ "admin", "services", "service_weburl", "log" }, form("service_weburl/log"), _("Service Log"), 40).leaf = true
    -- 注册 API 端点（无页面，仅处理请求）
    entry({ "admin", "services", "service_weburl", "list" }, call("action_list")).leaf = true -- 运行状态
    entry({ "admin", "services", "service_weburl", "edit"}, call("action_edit")).leaf = true
    entry({ "admin", "services", "service_weburl", "delete"}, call("action_delete")).leaf = true
    entry({ "admin", "services", "service_weburl", "logtail" }, call("action_logtail")).leaf = true -- 日志采集
    entry({ "admin", "services", "service_weburl", "invalidate-cache" }, call("action_invalidate_cache")).leaf = true -- 清除缓存
end

-- 数据列表
function action_list()
    local db = require "service_weburl.db"
    local services = db.query_services()
    luci.template.render("service_weburl/list", {services = services})
end

-- 编辑数据处理
function action_edit()
    local id = luci.http.formvalue("id")
    if not id or not tonumber(id) then
        luci.http.status(400, "Invalid ID")
        return
    end
    local db = require "service_weburl.db"
    local service = db.get_service_by_id(id)
    if not service then
        luci.http.redirect(luci.dispatcher.build_url("admin/services/service_weburl"))
        return
    end
    luci.template.render("service_weburl/edit", {service = service})
end

-- 删除处理
function action_delete()
    local id = luci.http.formvalue("id")
    if not id or not tonumber(id) then
        luci.http.status(400, "Invalid ID")
        return
    end
    local db = require "service_weburl.db"
    local service = db.get_service_by_id(id)
    if service then
        db.delete_service(id)
        luci.http.redirect(luci.dispatcher.build_url("admin/services/service_weburl"))
    else
        luci.http.status(404, "Service not found")
    end
end

function action_logtail()
    local db = require "service_weburl.db"
    local logs = db.query_logs()
    local log_text = ""
    for _, log in pairs(logs) do
        log_text = log_text .. log.timestamp .. " [" .. log.action .. "] " .. log.message .. "\n"
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json({ log = log_text })
end
