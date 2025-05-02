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
    local db_conn = db.init_db()
    if not db_conn then
        http.status(500, "Database Error")
        return
    end

    local page = tonumber(http.formvalue("page")) or 1
    local limit = 20
    local offset = (page - 1) * limit

    -- 获取总日志数
    local total = db_conn:first_row("SELECT COUNT(*) as count FROM logs").count

    -- 获取分页日志
    local stmt = db_conn:prepare("SELECT * FROM logs ORDER BY timestamp DESC LIMIT ? OFFSET ?")
    stmt:bind_values(limit, offset)
    
    local logs = {}
    for row in stmt:nrows() do
        table.insert(logs, row)
    end
    stmt:finalize()
    db_conn:close()

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
