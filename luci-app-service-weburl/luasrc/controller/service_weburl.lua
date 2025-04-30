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

-- 统一API响应函数
local function api_response(success, data, message, status)
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = success,
        data = data or {},
        message = message or "",
        timestamp = os.time()
    })
    if not success and status then
        luci.http.status(status)
    end
end

-- 检查权限
local function check_permission()
    if not luci.dispatcher.authenticated then
        api_response(false, nil, "Unauthorized", 401)
        return false
    end
    return true
end

-- 数据列表
function action_list()
    if not check_permission() then return end
    
    local db = require "service_weburl.db"
    local services, err = db.query_services()
    if not services then
        api_response(false, nil, "Failed to get services: "..tostring(err), 500)
        return
    end
    api_response(true, {services = services})
end

-- 编辑数据处理
function action_edit()
    if not check_permission() then return end
    
    local id = luci.http.formvalue("id")
    if not id or not tonumber(id) then
        api_response(false, nil, "Invalid ID", 400)
        return
    end
    
    local db = require "service_weburl.db"
    local service, err = db.get_service_by_id(id)
    if not service then
        api_response(false, nil, "Service not found: "..tostring(err), 404)
        return
    end
    
    api_response(true, {service = service})
end

-- 删除处理
function action_delete()
    if not check_permission() then return end
    
    local id = luci.http.formvalue("id")
    if not id or not tonumber(id) then
        api_response(false, nil, "Invalid ID", 400)
        return
    end
    
    local db = require "service_weburl.db"
    local service, err = db.get_service_by_id(id)
    if not service then
        api_response(false, nil, "Service not found", 404)
        return
    end
    
    local success, err = db.delete_service(id)
    if not success then
        api_response(false, nil, "Failed to delete service: "..tostring(err), 500)
        return
    end
    
    api_response(true, nil, "Service deleted successfully")
end

function action_logtail()
    if not check_permission() then return end
    
    local db = require "service_weburl.db"
    local logs, err = db.query_logs()
    if not logs then
        api_response(false, nil, "Failed to get logs: "..tostring(err), 500)
        return
    end
    
    local log_text = ""
    for _, log in ipairs(logs) do
        log_text = log_text .. log.timestamp .. " [" .. log.action .. "] " .. (log.message or "") .. "\n"
    end
    
    api_response(true, {log = log_text})
end

function action_invalidate_cache()
    if not check_permission() then return end
    
    local ok, err = pcall(function()
        os.execute("rm -rf /tmp/service_weburl_cache*")
        return true
    end)
    
    if not ok then
        api_response(false, nil, "Failed to clear cache: "..tostring(err), 500)
        return
    end
    
    api_response(true, nil, "Cache cleared successfully")
end