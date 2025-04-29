local lsqlite3 = require "lsqlite3"

local M = {}

function M.init_db()
    local db = lsqlite3.open("/etc/service_weburl/data.db")
    db:exec[[
        CREATE TABLE IF NOT EXISTS services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            url TEXT NOT NULL,
            description TEXT
        );
        CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            action TEXT,
            message TEXT
        );
    ]]
    db:close()
end

function M.query_services()
    local db = lsqlite3.open("/etc/service_weburl/data.db")
    local services = {}
    for row in db:nrows("SELECT * FROM services") do
        table.insert(services, row)
    end
    db:close()
    return services
end

function M.get_service_by_id(id)
    local db = lsqlite3.open("/etc/service_weburl/data.db")
    local service = db:first_row("SELECT * FROM services WHERE id = ?", id)
    db:close()
    return service or nil
end

function M.add_service(title, url, description)
    local db = lsqlite3.open("/etc/service_weburl/data.db")
    db:exec("INSERT INTO services (title, url, description) VALUES (?, ?, ?)",
        title, url, description)
    M.log_action("ADD", "Added service: "..title)
    db:close()
end

function M.update_service(id, title, url, description)
    local db = lsqlite3.open("/etc/service_weburl/data.db")
    db:exec("UPDATE services SET title=?, url=?, description=? WHERE id=?", 
        title, url, description, id)
    M.log_action("EDIT", "Updated service: "..title)
    db:close()
end

function M.delete_service(id)
    local db = lsqlite3.open("/etc/service_weburl/data.db")
    db:exec("DELETE FROM services WHERE id = ?", id)
    M.log_action("DELETE", "Deleted service ID: "..id)
    db:close()
end

function M.log_action(action, message)
    local db = lsqlite3.open("/etc/service_weburl/data.db")
    db:exec("INSERT INTO logs (action, message) VALUES (?, ?)", action, message)
    db:close()
end

return M
