local sqlite = require "lsqlite3"
local os = require "os"
local json = require "luci.jsonc"

local M = {}

-- 数据库文件路径
local DB_PATH = "/var/lib/service_weburl.db"

-- 初始化数据库
function M.init_db()
    local db = sqlite.open(DB_PATH)
    if not db then
        return nil, "Failed to open database"
    end

    -- 启用外键约束
    db:exec("PRAGMA foreign_keys = ON")

    -- 创建服务表（如果不存在）
    local sql = [[
        CREATE TABLE IF NOT EXISTS services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL CHECK(length(title) <= 255),
            url TEXT NOT NULL CHECK(length(url) <= 1024),
            description TEXT CHECK(length(description) <= 1024),
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ]]
    local ret = db:exec(sql)
    if ret ~= sqlite.OK then
        db:close()
        return nil, "Failed to create services table: " .. db:errmsg()
    end

    -- 创建日志表（如果不存在）
    sql = [[
        CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            action TEXT NOT NULL CHECK(length(action) <= 50),
            message TEXT CHECK(length(message) <= 1024),
            service_id INTEGER,
            FOREIGN KEY(service_id) REFERENCES services(id) ON DELETE CASCADE
        )
    ]]
    ret = db:exec(sql)
    if ret ~= sqlite.OK then
        db:close()
        return nil, "Failed to create logs table: " .. db:errmsg()
    end

    -- 创建索引（如果不存在）
    local indexes = {
        "CREATE INDEX IF NOT EXISTS idx_services_updated ON services(updated_at)",
        "CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs(timestamp)",
        "CREATE INDEX IF NOT EXISTS idx_logs_service ON logs(service_id)"
    }
    
    for _, sql in ipairs(indexes) do
        db:exec(sql)
    end

    -- 创建更新触发器
    sql = [[
        CREATE TRIGGER IF NOT EXISTS update_service_timestamp 
        AFTER UPDATE ON services 
        BEGIN
            UPDATE services SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
        END
    ]]
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
    -- 启用外键约束
    db:exec("PRAGMA foreign_keys = ON")
    return db
end

-- 记录日志（更新版，支持关联服务ID）
function M.log_action(action, message, service_id)
    local db = M.get_db()
    if not db then return nil, "Database not available" end

    local stmt = db:prepare("INSERT INTO logs(action, message, service_id) VALUES(?, ?, ?)")
    if not stmt then
        db:close()
        return nil, "Failed to prepare statement: " .. db:errmsg()
    end

    stmt:bind_values(action, message, service_id)
    local ret = stmt:step()
    stmt:finalize()
    db:close()

    if ret ~= sqlite.DONE then
        return nil, "Failed to log action: " .. db:errmsg()
    end
    return true
end

-- 添加服务（更新版）
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
    
    local service_id = db:last_insert_rowid()
    db:close()

    if ret ~= sqlite.DONE then
        return nil, "Failed to add service: " .. db:errmsg()
    end

    -- 记录日志并关联服务ID
    M.log_action("add_service", json.encode({title=title, url=url}), service_id)
    return service_id
end

-- 获取所有服务（按更新时间排序）
function M.get_services()
    local db = M.get_db()
    if not db then return nil, "Database not available" end

    local services = {}
    for row in db:nrows("SELECT * FROM services ORDER BY updated_at DESC") do
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

    -- 记录日志并关联服务ID
    M.log_action("update_service", json.encode({
        title = title, 
        url = url
    }), id)
    return true
end

-- 删除服务（会自动删除关联日志）
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

    -- 记录删除操作（不需要关联ID，因为已经删除）
    if service then
        M.log_action("delete_service", json.encode({
            id = id,
            title = service.title,
            url = service.url
        }), nil)
    end
    return true
end

-- 获取日志（支持按服务ID筛选）
function M.get_logs(service_id, limit)
    local db = M.get_db()
    if not db then return nil, "Database not available" end

    local logs = {}
    local where = service_id and "WHERE service_id = " .. service_id or ""
    local limit_clause = limit and "LIMIT " .. tonumber(limit) or ""
    
    local sql = string.format("SELECT * FROM logs %s ORDER BY timestamp DESC %s", where, limit_clause)

    for row in db:nrows(sql) do
        if row.message and row.message ~= "" then
            row.message = json.decode(row.message)
        end
        table.insert(logs, row)
    end
    db:close()
    return logs
end

-- 初始化数据库
M.init_db()

return M