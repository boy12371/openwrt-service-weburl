module("luci.controller.service_weburl", package.seeall)

local sqlite3 = require "lsqlite3"
local util = require "luci.util"
local http = require "luci.http"
local json = require "luci.jsonc"

function index()
    entry({"admin", "services", "service_weburl"}, alias("admin", "services", "service_weburl", "index"), _("Service WebURL"), 60)
    entry({"admin", "services", "service_weburl", "index"}, template("service_weburl/index"), _("Services List"), 1)
    entry({"admin", "services", "service_weburl", "add"}, template("service_weburl/add"), _("Add Service"), 2)
    entry({"admin", "services", "service_weburl", "log"}, template("service_weburl/log"), _("Logs"), 3)
    
    entry({"admin", "services", "service_weburl", "get_services"}, call("get_services"), nil)
    entry({"admin", "services", "service_weburl", "add_service"}, call("add_service"), nil)
    entry({"admin", "services", "service_weburl", "edit_service"}, call("edit_service"), nil)
    entry({"admin", "services", "service_weburl", "delete_service"}, call("delete_service"), nil)
    entry({"admin", "services", "service_weburl", "get_logs"}, call("get_logs"), nil)
end

local function log_action(action, details)
    local db = sqlite3.open("/etc/service_weburl/data.db")
    if db then
        local stmt = db:prepare("INSERT INTO logs (action, details) VALUES (?, ?)")
        stmt:bind_values(action, details)
        stmt:step()
        stmt:finalize()
        db:close()
    end
end

function get_services()
    local db = sqlite3.open("/etc/service_weburl/data.db")
    local result = {}
    
    if db then
        for row in db:nrows("SELECT * FROM services ORDER BY created_at DESC") do
            table.insert(result, row)
        end
        db:close()
    end
    
    http.prepare_content("application/json")
    http.write_json(result)
end

function add_service()
    local post = http.formvalue()
    local title = post.title
    local url = post.url
    local description = post.description or ""
    
    if not title or not url then
        http.prepare_content("application/json")
        http.write_json({success = false, message = "Missing required fields"})
        return
    end
    
    local db = sqlite3.open("/etc/service_weburl/data.db")
    if db then
        local stmt = db:prepare("INSERT INTO services (title, url, description) VALUES (?, ?, ?)")
        stmt:bind_values(title, url, description)
        stmt:step()
        stmt:finalize()
        db:close()
        
        log_action("add", string.format("Added service: %s", title))
        
        http.prepare_content("application/json")
        http.write_json({success = true})
    else
        http.prepare_content("application/json")
        http.write_json({success = false, message = "Database error"})
    end
end

function edit_service()
    local post = http.formvalue()
    local id = post.id
    local title = post.title
    local url = post.url
    local description = post.description or ""
    
    if not id or not title or not url then
        http.prepare_content("application/json")
        http.write_json({success = false, message = "Missing required fields"})
        return
    end
    
    local db = sqlite3.open("/etc/service_weburl/data.db")
    if db then
        local stmt = db:prepare("UPDATE services SET title = ?, url = ?, description = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?")
        stmt:bind_values(title, url, description, id)
        stmt:step()
        stmt:finalize()
        db:close()
        
        log_action("edit", string.format("Edited service: %s", title))
        
        http.prepare_content("application/json")
        http.write_json({success = true})
    else
        http.prepare_content("application/json")
        http.write_json({success = false, message = "Database error"})
    end
end

function delete_service()
    local post = http.formvalue()
    local id = post.id
    
    if not id then
        http.prepare_content("application/json")
        http.write_json({success = false, message = "Missing service ID"})
        return
    end
    
    local db = sqlite3.open("/etc/service_weburl/data.db")
    if db then
        local stmt = db:prepare("DELETE FROM services WHERE id = ?")
        stmt:bind_values(id)
        stmt:step()
        stmt:finalize()
        db:close()
        
        log_action("delete", string.format("Deleted service ID: %s", id))
        
        http.prepare_content("application/json")
        http.write_json({success = true})
    else
        http.prepare_content("application/json")
        http.write_json({success = false, message = "Database error"})
    end
end

function get_logs()
    local db = sqlite3.open("/etc/service_weburl/data.db")
    local result = {}
    
    if db then
        for row in db:nrows("SELECT * FROM logs ORDER BY created_at DESC LIMIT 100") do
            table.insert(result, row)
        end
        db:close()
    end
    
    http.prepare_content("application/json")
    http.write_json(result)
end