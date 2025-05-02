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
    entry({"admin", "services", "project-weburl", "log"}, call("action_log"), _("Logs"), 50).leaf = true
    
    -- 注册QR码相关路由
    entry({"admin", "services", "project-weburl", "qrcode"}, call("action_qrcode"), _("QR Code"), 60).leaf = true
    entry({"admin", "services", "project-weburl", "qrcode", "generate", "%d+"}, call("action_generate_qrcode")).leaf = true
    entry({"admin", "services", "project-weburl", "qrcode", "download", "%d+"}, call("action_download_qrcode")).leaf = true
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

    template.render("project-weburl/log", {
        logs = logs,
        pagination = {
            page = page,
            limit = limit,
            total = total,
            pages = math.ceil(total / limit)
        }
    })
end

-- QR码展示页面
function action_qrcode()
    local id = tonumber(http.formvalue("id") or luci.dispatcher.context.path[5])
    if not id then
        http.status(400, "Missing service ID")
        return
    end

    local db_conn = db.init_db()
    if not db_conn then
        http.status(500, "Database Error")
        return
    end

    local service = db.get_service(db_conn, id)
    db_conn:close()

    if not service or not service.url then
        http.status(404, "Service not found")
        return
    end

    template.render("project-weburl/qrcode", {
        service = service
    })
end

-- 生成QR码图片
function action_generate_qrcode()
    local id = tonumber(luci.dispatcher.context.path[6])
    if not id then
        http.status(400, "Missing service ID")
        return
    end

    local db_conn = db.init_db()
    if not db_conn then
        http.status(500, "Database Error")
        return
    end

    local service = db.get_service(db_conn, id)
    db_conn:close()

    if not service or not service.url then
        http.status(404, "Service not found")
        return
    end

    -- 生成QR码
    local qrcode = io.popen(string.format("qrencode -o - '%s'", service.url:gsub("'", "'\\''")))
    if not qrcode then
        http.status(500, "Failed to generate QR code")
        return
    end

    http.header("Content-Type", "image/png")
    http.prepare_content("image/png")
    http.write(qrcode:read("*a"))
    qrcode:close()
end

-- 下载QR码图片
function action_download_qrcode()
    local id = tonumber(luci.dispatcher.context.path[6])
    if not id then
        http.status(400, "Missing service ID")
        return
    end

    local db_conn = db.init_db()
    if not db_conn then
        http.status(500, "Database Error")
        return
    end

    local service = db.get_service(db_conn, id)
    db_conn:close()

    if not service or not service.url then
        http.status(404, "Service not found")
        return
    end

    -- 生成QR码
    local qrcode = io.popen(string.format("qrencode -o - '%s'", service.url:gsub("'", "'\\''")))
    if not qrcode then
        http.status(500, "Failed to generate QR code")
        return
    end

    http.header("Content-Type", "image/png")
    http.header("Content-Disposition", string.format('attachment; filename="%s-qrcode.png"', service.title:gsub("[^%w]", "-")))
    http.prepare_content("image/png")
    http.write(qrcode:read("*a"))
    qrcode:close()
end