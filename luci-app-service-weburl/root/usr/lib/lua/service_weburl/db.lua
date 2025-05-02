local sqlite3 = require "lsqlite3"
local nixio = require "nixio"
local util = require "luci.util"
local config = require "luci.model.cbi.service_weburl.config"

local M = {}

-- 从配置获取数据库路径
local DB_PATH = config.get_config().db_path

-- 设置数据库文件权限
local function set_db_permissions()
    local perms = config.get_config().db_perms
    if nixio.fs.stat(DB_PATH) then
        nixio.fs.chmod(DB_PATH, perms)
    end
end

-- 初始化数据库连接
function M.init_db()
    -- 确保数据库目录存在
    nixio.fs.mkdir("/etc/config")
    
    local db, err = sqlite3.open(DB_PATH)
    if not db then
        util.perror("Failed to open database: " .. (err or "unknown error"))
        return nil, err
    end
    
    -- 启用外键约束
    db:exec("PRAGMA foreign_keys = ON")
    
    -- 初始化表结构
    local success, err = db:exec([[
        CREATE TABLE IF NOT EXISTS services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            url TEXT NOT NULL,
            description TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            action TEXT NOT NULL,
            message TEXT,
            service_id INTEGER,
            FOREIGN KEY(service_id) REFERENCES services(id) ON DELETE CASCADE
        );
        
        CREATE TRIGGER IF NOT EXISTS update_service_timestamp 
        AFTER UPDATE ON services 
        BEGIN
            UPDATE services SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
        END;
    ]])
    
    if not success then
        db:close()
        util.perror("Failed to initialize database: " .. (err or "unknown error"))
        return nil, err
    end
    
    return db
end

-- 获取所有服务
function M.get_services(db)
    local stmt = db:prepare("SELECT * FROM services ORDER BY updated_at DESC")
    if not stmt then return nil end
    
    local services = {}
    for row in stmt:nrows() do
        table.insert(services, row)
    end
    stmt:finalize()
    return services
end

-- 获取单个服务
function M.get_service(db, id)
    local stmt = db:prepare("SELECT * FROM services WHERE id = ?")
    stmt:bind(1, id)
    
    local service = stmt:first_row()
    stmt:finalize()
    return service
end

-- 添加服务
function M.add_service(db, title, url, description)
    -- 输入验证
    if not title or type(title) ~= "string" or #title > 100 then
        return nil, "Invalid title (max 100 chars)"
    end
    
    if not url or not url:match("^https?://[%w-_%.%?%.:/%+=&]+$") then
        return nil, "Invalid URL format"
    end
    
    description = description and #description > 0 and description or nil
    
    local stmt, err = db:prepare("INSERT INTO services (title, url, description) VALUES (?, ?, ?)")
    if not stmt then return nil, err end
    
    stmt:bind_values(title, url, description)
    local success, err = stmt:step()
    stmt:finalize()
    
    if success then
        set_db_permissions()
        return db:last_insert_rowid()
    end
    return nil, err or "Failed to add service"
end

-- 更新服务
function M.update_service(db, id, title, url, description)
    local stmt = db:prepare("UPDATE services SET title = ?, url = ?, description = ? WHERE id = ?")
    stmt:bind_values(title, url, description, id)
    local success = stmt:step()
    stmt:finalize()
    return success
end

-- 删除服务
function M.delete_service(db, id)
    local stmt = db:prepare("DELETE FROM services WHERE id = ?")
    stmt:bind(1, id)
    local success = stmt:step()
    stmt:finalize()
    return success
end

-- 记录日志
function M.log_action(db, action, message, service_id)
    local stmt = db:prepare("INSERT INTO logs (action, message, service_id) VALUES (?, ?, ?)")
    stmt:bind_values(action, message, service_id)
    local success = stmt:step()
    stmt:finalize()
    return success
end

-- 获取日志
function M.get_logs(db, limit)
    limit = limit or 100
    local stmt = db:prepare("SELECT * FROM logs ORDER BY timestamp DESC LIMIT ?")
    stmt:bind(1, limit)
    
    local logs = {}
    for row in stmt:nrows() do
        table.insert(logs, row)
    end
    stmt:finalize()
    return logs
end

-- 事务执行
function M.transaction(db, func)
    local success, err
    db:exec("BEGIN TRANSACTION")
    success, err = pcall(func, db)
    if success then
        db:exec("COMMIT")
    else
        db:exec("ROLLBACK")
    end
    return success, err
end

-- 获取分页日志
function M.get_paginated_logs(db_conn, page, limit)
    page = page or 1
    limit = limit or 20
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

    return {
        logs = logs,
        pagination = {
            page = page,
            limit = limit,
            total = total,
            pages = math.ceil(total / limit)
        }
    }
end

return M