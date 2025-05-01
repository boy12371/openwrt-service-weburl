local sqlite = require "lsqlite3"
local os = require "os"

local M = {}

-- 数据库文件路径
local DB_PATH = "/var/lib/service_weburl.db"

-- 初始化数据库
function M.init_db()
    local db = sqlite.open(DB_PATH)
    if not db then
        return nil, "Failed to open database"
    end

    -- 创建服务表
    local sql = [[
        CREATE TABLE IF NOT EXISTS services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            url TEXT NOT NULL,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]]
    local ret = db:exec(sql)
    if ret ~= sqlite.OK then
        db:close()
        return nil, "Failed to create services table: " .. db:errmsg()
    end

    -- 创建日志表
    sql = [[
        CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT NOT NULL,
            data TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]]
    ret = db:exec(sql)
    if ret ~= sqlite.OK then
        db:close()
        return nil, "Failed to create logs table: " .. db:errmsg()
    end

    -- 创建索引
    sql = "CREATE INDEX IF NOT EXISTS idx_services_title ON services(title)"
    db:exec(sql)
    
    sql = "CREATE INDEX IF NOT EXISTS idx_logs_created ON logs(created_at)"
    db:exec(sql)

    db:close()
    return true
end

-- 获取数据库连接
function M.get_db()
    local db, err = sqlite.open(DB_PATH)
    if not db then
        return nil, err or "Failed to open database"
    end
    return db
end

-- 记录日志
function M.log_action(action, data)
    local db = M.get_db()
    if not db then return nil, "Database not available" end

    local stmt = db:prepare("INSERT INTO logs(action, data) VALUES(?, ?)")
    if not stmt then
        db:close()
        return nil, "Failed to prepare statement: " .. db:errmsg()
    end

    stmt:bind_values(action, data and json.encode(data) or "")
    local ret = stmt:step()
    stmt:finalize()
    db:close()

    if ret ~= sqlite.DONE then
        return nil, "Failed to log action: " .. db:errmsg()
    end
    return true
end

-- 添加服务
function M.add_service(title, url, description)
    local db = M.get_db()
    if not db then return nil, "Database not available" end

    local stmt = db:prepare("INSERT INTO services(title, url, description) VALUES(?, ?, ?)")
    if not stmt then
        db:close()
        return nil, "Failed to prepare statement: " .. db:errmsg()
    end

    stmt:bind_values(title, url, description)
    local ret = stmt:step()
    stmt:finalize()
    db:close()

    if ret ~= sqlite.DONE then
        return nil, "Failed to add service: " .. db:errmsg()
    end

    -- 记录日志
    M.log_action("add_service", {title = title, url = url})
    return true
end

-- 获取所有服务
function M.get_services()
    local db = M.get_db()
    if not db then return nil, "Database not available" end

    local services = {}
    for row in db:nrows("SELECT * FROM services ORDER BY created_at DESC") do
        table.insert(services, row)
    end
    db:close()
    return services
end

-- 更新服务
function M.update_service(id, title, url, description)
    local db = M.get_db()
    if not db then return nil, "Database not available" end

    local stmt = db:prepare("UPDATE services SET title = ?, url = ?, description = ? WHERE id = ?")
    if not stmt then
        db:close()
        return nil, "Failed to prepare statement: " .. db:errmsg()
    end

    stmt:bind_values(title, url, description, id)
    local ret = stmt:step()
    stmt:finalize()
    db:close()

    if ret ~= sqlite.DONE then
        return nil, "Failed to update service: " .. db:errmsg()
    end

    -- 记录日志
    M.log_action("update_service", {id = id, title = title, url = url})
    return true
end

-- 删除服务
function M.delete_service(id)
    local db = M.get_db()
    if not db then return nil, "Database not available" end

    -- 先获取服务信息用于日志记录
    local service
    for row in db:nrows("SELECT * FROM services WHERE id = " .. id) do
        service = row
        break
    end

    local stmt = db:prepare("DELETE FROM services WHERE id = ?")
    if not stmt then
        db:close()
        return nil, "Failed to prepare statement: " .. db:errmsg()
    end

    stmt:bind_values(id)
    local ret = stmt:step()
    stmt:finalize()
    db:close()

    if ret ~= sqlite.DONE then
        return nil, "Failed to delete service: " .. db:errmsg()
    end

    -- 记录日志
    if service then
        M.log_action("delete_service", {id = id, title = service.title, url = service.url})
    end
    return true
end

-- 获取日志
function M.get_logs(limit)
    local db = M.get_db()
    if not db then return nil, "Database not available" end

    local logs = {}
    local sql = "SELECT * FROM logs ORDER BY created_at DESC"
    if limit then
        sql = sql .. " LIMIT " .. tonumber(limit)
    end

    for row in db:nrows(sql) do
        if row.data and row.data ~= "" then
            row.data = json.decode(row.data)
        end
        table.insert(logs, row)
    end
    db:close()
    return logs
end

-- 初始化数据库
M.init_db()

return M