module("luci.controller.service_weburl", package.seeall)

local service = require "luci.model.cbi.service_weburl.service"
local db = require "service_weburl.db"
local http = require "luci.http"
local sys = require "luci.sys"
local util = require "luci.util"

function index()
    -- 注册服务管理相关路由
    service.index()
    
    -- 注册日志查看路由
    entry({"admin", "services", "service_weburl", "log"}, call("action_log"), _("Logs"), 50).leaf = true
end

-- 日志查看功能
function action_log()
    local log_model = require "luci.model.cbi.service_weburl.log"
    return log_model.action_log()
    local log_model = require "luci.model.cbi.service_weburl.log"
    local page = tonumber(http.formvalue("page")) or 1
    local limit = 20
    
    -- 调用模型层获取日志数据
    local logs, total = log_model.get_logs(page, limit)
    
    template.render("service_weburl/log", {
        logs = logs,
        pagination = {
            page = page,
            limit = limit,
            total = total,
            pages = math.ceil(total / limit)
        }
    })
end