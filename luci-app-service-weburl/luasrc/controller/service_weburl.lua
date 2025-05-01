module("luci.controller.service_weburl", package.seeall)

function index()
    local page
    
    -- 权限控制
    page = entry({"admin", "services"}, firstchild(), _("服务管理"), 60)
    page.dependent = false
    
    -- 服务列表页
    entry({"admin", "services", "index"}, call("action_index"), _("服务列表"), 10)
    
    -- 服务设置页
    entry({"admin", "services", "settings"}, call("action_settings"), _("服务设置"), 20)
    
    -- 日志查看页
    entry({"admin", "services", "logs"}, call("action_logs"), _("操作日志"), 30)
    
    -- 表单提交处理
    entry({"admin", "services", "add_service"}, post("action_add_service"))
    entry({"admin", "services", "update_service"}, post("action_update_service"))
    entry({"admin", "services", "delete_service"}, post("action_delete_service"))
end

-- 服务列表页
function action_index()
    local service = require "luci.model.cbi.service_weburl.service"
    local http = require "luci.http"
    local template = require "luci.template"
    
    -- 获取服务列表
    local services, err = service.get_services()
    if not services then
        http.status(500, "获取服务列表失败: " .. (err or "未知错误"))
        return
    end
    
    -- 准备模板数据
    local data = {
        services = services,
        page_title = "服务列表"
    }
    
    -- 渲染模板
    template.render("service_weburl/index", data)
end

-- 服务设置页
function action_settings()
    local http = require "luci.http"
    local template = require "luci.template"
    local service = require "luci.model.cbi.service_weburl.service"
    
    -- 获取查询参数
    local id = http.formvalue("id")
    local service_data
    
    -- 如果是编辑模式，获取服务数据
    if id and id ~= "" then
        service_data = service.get_service(id)
        if not service_data then
            http.redirect(luci.dispatcher.build_url("admin/services/index"))
            return
        end
    end
    
    -- 准备模板数据
    local data = {
        service = service_data,
        page_title = service_data and "编辑服务" or "添加服务",
        is_edit = service_data and true or false
    }
    
    -- 渲染模板
    template.render("service_weburl/settings", data)
end

-- 添加服务处理
function action_add_service()
    local http = require "luci.http"
    local service = require "luci.model.cbi.service_weburl.service"
    
    -- 获取表单数据
    local title = http.formvalue("title")
    local url = http.formvalue("url")
    local description = http.formvalue("description")
    
    -- 添加服务
    local service_id, err = service.add_service(title, url, description)
    if not service_id then
        http.status(400, err or "添加服务失败")
        return
    end
    
    -- 返回成功响应
    http.prepare_content("application/json")
    http.write_json({
        success = true, 
        message = "服务添加成功",
        service_id = service_id
    })
end

-- 更新服务处理
function action_update_service()
    local http = require "luci.http"
    local service = require "luci.model.cbi.service_weburl.service"
    
    -- 获取表单数据
    local id = http.formvalue("id")
    local title = http.formvalue("title")
    local url = http.formvalue("url")
    local description = http.formvalue("description")
    
    -- 更新服务
    local ok, err = service.update_service(id, title, url, description)
    if not ok then
        http.status(400, err or "更新服务失败")
        return
    end
    
    -- 返回成功响应
    http.prepare_content("application/json")
    http.write_json({
        success = true, 
        message = "服务更新成功"
    })
end

-- 删除服务处理
function action_delete_service()
    local http = require "luci.http"
    local service = require "luci.model.cbi.service_weburl.service"
    
    -- 获取要删除的服务ID
    local id = http.formvalue("id")
    
    -- 删除服务
    local ok, err = service.delete_service(id)
    if not ok then
        http.status(400, err or "删除服务失败")
        return
    end
    
    -- 返回成功响应
    http.prepare_content("application/json")
    http.write_json({
        success = true, 
        message = "服务删除成功"
    })
end

-- 日志查看页
function action_logs()
    local http = require "luci.http"
    local template = require "luci.template"
    local log = require "luci.model.cbi.service_weburl.log"
    
    -- 获取查询参数
    local page = tonumber(http.formvalue("page")) or 1
    local page_size = 20
    local offset = (page - 1) * page_size
    
    -- 获取日志
    local result = log.query_logs({
        limit = page_size,
        offset = offset,
        need_total = true
    })
    
    if not result then
        http.status(500, "获取日志失败")
        return
    end
    
    -- 准备模板数据
    local data = {
        logs = result.logs,
        total = result.total,
        page = page,
        page_size = page_size,
        page_title = "操作日志"
    }
    
    -- 渲染模板
    template.render("service_weburl/logs", data)
end