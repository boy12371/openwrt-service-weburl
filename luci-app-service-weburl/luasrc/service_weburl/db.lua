local lsqlite3 = require "lsqlite3"
local M = {}
local db_conn = nil

function M.init_db()
    local ok, err = pcall(function()
        db_conn = lsqlite3.open("/etc/config/data.db")
        db_conn:exec[[
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
    end)
    if not ok then
        luci.logger:error("DB初始化失败: " .. tostring(err))
        return nil, err
    end
end

function M.query_services()
    if not db_conn then M.init_db() end
    local services = {}
    for row in db_conn:nrows("SELECT * FROM services") do
        table.insert(services, row)
    end
    return services
end

function M.get_service_by_id(id)
    if not db_conn then M.init_db() end
    local service = db_conn:first_row("SELECT * FROM services WHERE id = ?", id)
    return service
end

function M.add_service(title, url, description)
    if not db_conn then M.init_db() end
    db_conn:exec("INSERT INTO services (title, url, description) VALUES (?, ?, ?)", title, url, description)
    M.log_action("ADD", "Added service: "..title)
end

function M.update_service(id, title, url, description)
    if not db_conn then M.init_db() end
    db_conn:exec("UPDATE services SET title=?, url=?, description=? WHERE id=?", title, url, description, id)
    M.log_action("EDIT", "Updated service: "..title)
end

function M.delete_service(id)
    if not db_conn then M.init_db() end
    db_conn:exec("DELETE FROM services WHERE id = ?", id)
    M.log_action("DELETE", "Deleted service ID: "..id)
end

function M.log_action(action, message)
    db_conn:exec("INSERT INTO logs (action, message) VALUES (?, ?)", action, message)
end

return M
