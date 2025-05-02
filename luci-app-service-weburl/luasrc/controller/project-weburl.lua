module("luci.controller.project-weburl", package.seeall)

local db = require "project-weburl.db"
local http = require "luci.http"
local sys = require "luci.sys"
local util = require "luci.util"
local template = require "luci.template"

function index()
    entry({"admin", "services", "project-weburl"}, 
          call("action_index"), 
          _("Service WebURL"), 10).dependent = true
          
    entry({"admin", "services", "project-weburl", "add"}, 
          call("action_add"), 
          nil, 20).leaf = true
          
    entry({"admin", "services", "project-weburl", "edit"}, 
          call("action_edit"), 
          _("Edit Service"), 30).leaf = true
          
    entry({"admin", "services", "project-weburl", "delete"}, 
          call("action_delete"), 
          nil, 40).leaf = true
          
    entry({"admin", "services", "project-weburl", "log"}, 
          call("action_log"), 
          _("Logs"), 50).leaf = true
          
    entry({"admin", "services", "project-weburl", "qrcode"}, 
          call("action_qrcode"), 
          _("QR Code"), 60).leaf = true
          
    entry({"admin", "services", "project-weburl", "qrcode", "generate", "%d+"}, 
          call("action_generate_qrcode")).leaf = true
          
    entry({"admin", "services", "project-weburl", "qrcode", "download", "%d+"}, 
          call("action_download_qrcode")).leaf = true
end

-- [Previous action functions remain unchanged...]

-- Display QR code page
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

    if not service then
        http.status(404, "Service not found")
        return
    end

    template.render("project-weburl/qrcode", {
        service = service
    })
end

-- Generate QR code image
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

    -- Generate QR code using qrencode
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

-- Download QR code image
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

    -- Generate QR code using qrencode
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