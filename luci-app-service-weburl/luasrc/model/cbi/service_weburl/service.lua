local db = require "service_weburl.db"
local sys = require "luci.sys"
local http = require "luci.http"
local util = require "luci.util"
local uci = require "luci.model.uci".cursor()

module("luci.model.cbi.service_weburl.service", package.seeall)

function index()
    entry({"admin", "services", "service_weburl"}, call("action_index"), _("Service WebURL"), 10).index = true
    entry({"admin", "services", "service_weburl", "add"}, call("action_add"), nil, 20).leaf = true
    entry({"admin", "services", "service_weburl", "edit"}, call("action_edit"), nil, 30).leaf = true
    entry({"admin", "services", "service_weburl", "delete"}, call("action_delete"), nil, 40).leaf = true
end

function validate_service(form)
    if not form.title or #form.title == 0 then
        return false, "Title is required"
    end
    
    if not form.url or #form.url == 0 then
        return false, "URL is required"
    end
    
    if not form.url:match("^https?://") then
        return false, "URL must start with http:// or https://"
    end
    
    return true
end

function action_index()
    local db_conn = db.init_db()
    if not db_conn then
        http.status(500, "Database Error")
        return
    end

    local services = db.get_services(db_conn)
    db_conn:close()

    template.render("project-weburl/index", {
        services = services or {}
    })
end

function action_add()
    local db_conn = db.init_db()
    if not db_conn then
        http.status(500, "Database Error")
        return
    end

    if http.getenv("REQUEST_METHOD") == "POST" then
        local form = {
            title = http.formvalue("title"),
            url = http.formvalue("url"),
            description = http.formvalue("description")
        }
        
        local valid, err = validate_service(form)
        if not valid then
            http.status(400, err)
            return
        end
        
        local success, id = pcall(db.add_service, db_conn, form.title, form.url, form.description)
        if not success then
            http.status(500, "Failed to add service")
            return
        end
        
        db.log_action(db_conn, "CREATE", string.format("Added service: %s", form.title), id)
        http.redirect(luci.dispatcher.build_url("admin/services/service_weburl"))
    else
        template.render("service_weburl/edit", {
            service = {
                title = "",
                url = "http://",
                description = ""
            }
        })
    end
    
    db_conn:close()
end

function action_edit()
    local db_conn = db.init_db()
    if not db_conn then
        http.status(500, "Database Error")
        return
    end

    local id = tonumber(http.formvalue("id") or luci.dispatcher.context.path[5])
    if not id then
        http.status(400, "Missing service ID")
        return
    end

    local service = db.get_service(db_conn, id)
    if not service then
        http.status(404, "Service not found")
        return
    end

    if http.getenv("REQUEST_METHOD") == "POST" then
        local form = {
            id = id,
            title = http.formvalue("title"),
            url = http.formvalue("url"),
            description = http.formvalue("description")
        }
        
        local valid, err = validate_service(form)
        if not valid then
            http.status(400, err)
            return
        end
        
        local success = pcall(db.update_service, db_conn, id, form.title, form.url, form.description)
        if not success then
            http.status(500, "Failed to update service")
            return
        end
        
        db.log_action(db_conn, "UPDATE", string.format("Updated service: %s", form.title), id)
        http.redirect(luci.dispatcher.build_url("admin/services/service_weburl"))
    else
        template.render("service_weburl/edit", {
            service = service
        })
    end
    
    db_conn:close()
end

function action_delete()
    local db_conn = db.init_db()
    if not db_conn then
        http.status(500, "Database Error")
        return
    end

    local id = tonumber(http.formvalue("id") or luci.dispatcher.context.path[5])
    if not id then
        http.status(400, "Missing service ID")
        return
    end

    local service = db.get_service(db_conn, id)
    if not service then
        http.status(404, "Service not found")
        return
    end

    local success = pcall(db.delete_service, db_conn, id)
    if not success then
        http.status(500, "Failed to delete service")
        return
    end
    
    db.log_action(db_conn, "DELETE", string.format("Deleted service: %s", service.title), id)
            http.redirect(luci.dispatcher.build_url("admin/services/service_weburl"))
    
    db_conn:close()
end