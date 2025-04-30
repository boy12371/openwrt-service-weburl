local lsqlite3 = require "lsqlite3"
local M = {}
local db_conn = nil
local MAX_CONNECTION_ATTEMPTS = 3
local CONNECTION_RETRY_DELAY = 1 -- seconds

-- 带重试机制的数据库连接
local function connect_with_retry()
    local attempts = 0
    local conn, err
    
    while attempts < MAX_CONNECTION_ATTEMPTS do
        conn, err = lsqlite3.open("/etc/config/data.db")
        if conn then
            -- 设置数据库参数
            conn:exec("PRAGMA foreign_keys = ON")
            conn:exec("PRAGMA journal_mode = WAL")
            conn:exec("PRAGMA synchronous = NORMAL")
            conn:exec("PRAGMA busy_timeout = 5000")
            return conn
        end
        
        attempts = attempts + 1
        luci.logger:warning(string.format("DB connection attempt %d failed: %s", attempts, tostring(err)))
        os.execute("sleep " .. CONNECTION_RETRY_DELAY)
    end
    
    return nil, err or "Max connection attempts reached"
end

function M.init_db()
    if db_conn then return true end
    
    local ok, err = pcall(function()
        db_conn, err = connect_with_retry()
        if not db_conn then
            error("Failed to open database: " .. tostring(err))
        end

        -- 使用事务确保表创建原子性
        db_conn:exec("BEGIN TRANSACTION")
        
        local create_tables = [[
            CREATE TABLE IF NOT EXISTS services (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL CHECK(length(title) <= 255),
                url TEXT NOT NULL CHECK(length(url) <= 1024),
                description TEXT CHECK(length(description) <= 1024),
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE TABLE IF NOT EXISTS logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                action TEXT NOT NULL CHECK(length(action) <= 50),
                message TEXT CHECK(length(message) <= 1024),
                service_id INTEGER REFERENCES services(id) ON DELETE CASCADE
            );
            
            CREATE INDEX IF NOT EXISTS idx_services_updated ON services(updated_at);
            CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs(timestamp);
            CREATE INDEX IF NOT EXISTS idx_logs_service ON logs(service_id);
            
            CREATE TRIGGER IF NOT EXISTS update_service_timestamp 
            AFTER UPDATE ON services 
            BEGIN
                UPDATE services SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
            END;
        ]]
        
        local ok, err = db_conn:exec(create_tables)
        if not ok then
            error("Failed to create tables: " .. tostring(err))
        end
        
        db_conn:exec("COMMIT")
    end)
    
    if not ok then
        luci.logger:error("DB initialization failed: " .. tostring(err))
        if db_conn then
            db_conn:exec("ROLLBACK")
            db_conn:close()
            db_conn = nil
        end
        return false, err
    end
    return true
end

function M.close_db()
    if db_conn then
        db_conn:close()
        db_conn = nil
    end
    return true
end

function M.query_services()
    if not db_conn and not M.init_db() then
        return nil, "Database initialization failed"
    end
    
    local services = {}
    local stmt, err = db_conn:prepare("SELECT id, title, url, description, created_at, updated_at FROM services ORDER BY updated_at DESC")
    if not stmt then
        luci.logger:error("Failed to prepare services query: " .. (err or db_conn:errmsg()))
        return nil, err or db_conn:errmsg()
    end
    
    local ok, err = pcall(function()
        for row in stmt:nrows() do
            table.insert(services, row)
        end
    end)
    
    stmt:finalize()
    
    if not ok then
        luci.logger:error("Failed to fetch services: " .. tostring(err))
        return nil, err
    end
    
    return services
end

function M.get_service_by_id(id)
    if not db_conn and not M.init_db() then
        return nil, "Database initialization failed"
    end
    
    if not id or not tonumber(id) then
        return nil, "Invalid ID"
    end
    
    local stmt, err = db_conn:prepare("SELECT id, title, url, description, created_at, updated_at FROM services WHERE id = ?")
    if not stmt then
        luci.logger:error("Failed to prepare service query: " .. (err or db_conn:errmsg()))
        return nil, err or db_conn:errmsg()
    end
    
    local ok, err = pcall(function()
        stmt:bind(1, tonumber(id))
        return stmt:first_row()
    end)
    
    stmt:finalize()
    
    if not ok then
        luci.logger:error("Failed to fetch service: " .. tostring(err))
        return nil, err
    end
    
    return ok
end

function M.add_service(title, url, description)
    if not db_conn and not M.init_db() then
        return false, "Database initialization failed"
    end
    
    if not title or not url or type(title) ~= "string" or type(url) ~= "string" then
        return false, "Invalid parameters"
    end
    
    local ok, err = pcall(function()
        -- 开始事务
        db_conn:exec("BEGIN TRANSACTION")
        
        -- 插入服务
        local stmt = db_conn:prepare("INSERT INTO services (title, url, description) VALUES (?, ?, ?)")
        if not stmt then
            error("Failed to prepare insert statement: " .. db_conn:errmsg())
        end
        
        stmt:bind(1, title)
        stmt:bind(2, url)
        stmt:bind(3, description or "")
        
        if not stmt:step() then
            error("Failed to insert service: " .. db_conn:errmsg())
        end
        
        stmt:finalize()
        
        -- 获取最后插入的ID
        local last_id = db_conn:last_insert_rowid()
        
        -- 记录日志
        local log_ok, log_err = M.log_action("ADD", "Added service: "..title, last_id)
        if not log_ok then
            error("Failed to log action: " .. tostring(log_err))
        end
        
        -- 提交事务
        db_conn:exec("COMMIT")
        
        return true
    end)
    
    if not ok then
        db_conn:exec("ROLLBACK")
        luci.logger:error("Failed to add service: " .. tostring(err))
        return false, err
    end
    
    return true
end

function M.update_service(id, title, url, description)
    if not db_conn and not M.init_db() then
        return false, "Database initialization failed"
    end
    
    if not id or not title or not url or 
       not tonumber(id) or type(title) ~= "string" or type(url) ~= "string" then
        return false, "Invalid parameters"
    end
    
    local ok, err = pcall(function()
        -- 开始事务
        db_conn:exec("BEGIN TRANSACTION")
        
        -- 更新服务
        local stmt = db_conn:prepare("UPDATE services SET title = ?, url = ?, description = ? WHERE id = ?")
        if not stmt then
            error("Failed to prepare update statement: " .. db_conn:errmsg())
        end
        
        stmt:bind(1, title)
        stmt:bind(2, url)
        stmt:bind(3, description or "")
        stmt:bind(4, tonumber(id))
        
        if not stmt:step() then
            error("Failed to update service: " .. db_conn:errmsg())
        end
        
        stmt:finalize()
        
        -- 记录日志
        local log_ok, log_err = M.log_action("EDIT", "Updated service: "..title, tonumber(id))
        if not log_ok then
            error("Failed to log action: " .. tostring(log_err))
        end
        
        -- 提交事务
        db_conn:exec("COMMIT")
        
        return true
    end)
    
    if not ok then
        db_conn:exec("ROLLBACK")
        luci.logger:error("Failed to update service: " .. tostring(err))
        return false, err
    end
    
    return true
end

function M.delete_service(id)
    if not db_conn and not M.init_db() then
        return false, "Database initialization failed"
    end
    
    if not id or not tonumber(id) then
        return false, "Invalid ID"
    end
    
    local ok, err = pcall(function()
        -- 开始事务
        db_conn:exec("BEGIN TRANSACTION")
        
        -- 先获取服务标题用于日志
        local stmt = db_conn:prepare("SELECT title FROM services WHERE id = ?")
        if not stmt then
            error("Failed to prepare select statement: " .. db_conn:errmsg())
        end
        
        stmt:bind(1, tonumber(id))
        local service = stmt:first_row()
        stmt:finalize()
        
        if not service then
            error("Service not found")
        end
        
        -- 删除服务
        local stmt = db_conn:prepare("DELETE FROM services WHERE id = ?")
        if not stmt then
            error("Failed to prepare delete statement: " .. db_conn:errmsg())
        end
        
        stmt:bind(1, tonumber(id))
        
        if not stmt:step() then
            error("Failed to delete service: " .. db_conn:errmsg())
        end
        
        stmt:finalize()
        
        -- 记录日志
        local log_ok, log_err = M.log_action("DELETE", "Deleted service: "..service.title, tonumber(id))
        if not log_ok then
            error("Failed to log action: " .. tostring(log_err))
        end
        
        -- 提交事务
        db_conn:exec("COMMIT")
        
        return true
    end)
    
    if not ok then
        db_conn:exec("ROLLBACK")
        luci.logger:error("Failed to delete service: " .. tostring(err))
        return false, err
    end
    
    return true
end

function M.log_action(action, message, service_id)
    if not db_conn then
        return false, "Database not initialized"
    end
    
    if not action or type(action) ~= "string" then
        return false, "Invalid action"
    end
    
    local ok, err = pcall(function()
        local stmt = db_conn:prepare("INSERT INTO logs (action, message, service_id) VALUES (?, ?, ?)")
        if not stmt then
            error("Failed to prepare log statement: " .. db_conn:errmsg())
        end
        
        stmt:bind(1, action)
        stmt:bind(2, message or "")
        stmt:bind(3, service_id)
        
        if not stmt:step() then
            error("Failed to insert log: " .. db_conn:errmsg())
        end
        
        stmt:finalize()
        return true
    end)
    
    if not ok then
        luci.logger:error("Failed to log action: " .. tostring(err))
        return false, err
    end
    
    return true
end

return M