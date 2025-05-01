local db = require "luci.model.cbi.service_weburl.db"
local os = require "os"
local json = require "luci.jsonc"

local M = {}

-- 日志级别
M.LEVEL = {
    INFO = "INFO",
    WARN = "WARN",
    ERROR = "ERROR"
}

-- 记录日志
function M.log(level, action, data)
    if not M.LEVEL[level] then
        level = M.LEVEL.INFO
    end
    
    local log_data = {
        level = level,
        action = action,
        data = data
    }
    
    return db.log_action(action, log_data)
end

-- 查询日志
function M.query_logs(options)
    options = options or {}
    local where = {}
    local params = {}
    
    if options.action then
        table.insert(where, "action = ?")
        table.insert(params, options.action)
    end
    
    if options.level then
        table.insert(where, "json_extract(data, '$.level') = ?")
        table.insert(params, options.level)
    end
    
    if options.start_time then
        table.insert(where, "created_at >= ?")
        table.insert(params, os.date("%Y-%m-%d %H:%M:%S", options.start_time))
    end
    
    if options.end_time then
        table.insert(where, "created_at <= ?")
        table.insert(params, os.date("%Y-%m-%d %H:%M:%S", options.end_time))
    end
    
    local where_clause = #where > 0 and "WHERE " .. table.concat(where, " AND ") or ""
    local limit_clause = options.limit and "LIMIT " .. options.limit or ""
    local offset_clause = options.offset and "OFFSET " .. options.offset or ""
    
    local db_conn = db.get_db()
    if not db_conn then return nil, "Database not available" end
    
    local sql = string.format("SELECT * FROM logs %s ORDER BY created_at DESC %s %s",
        where_clause, limit_clause, offset_clause)
    
    local stmt = db_conn:prepare(sql)
    if not stmt then
        db_conn:close()
        return nil, "Failed to prepare statement"
    end
    
    for i, param in ipairs(params) do
        stmt:bind(i, param)
    end
    
    local logs = {}
    while stmt:step() == sqlite.ROW do
        local log = {
            id = stmt:get_value(0),
            action = stmt:get_value(1),
            data = stmt:get_value(2),
            created_at = stmt:get_value(3)
        }
        
        if log.data and log.data ~= "" then
            log.data = json.parse(log.data)
        end
        
        table.insert(logs, log)
    end
    
    stmt:finalize()
    
    -- 获取总数用于分页
    local total = 0
    if options.need_total then
        local count_sql = string.format("SELECT COUNT(*) FROM logs %s", where_clause)
        local count_stmt = db_conn:prepare(count_sql)
        if count_stmt then
            for i, param in ipairs(params) do
                count_stmt:bind(i, param)
            end
            
            if count_stmt:step() == sqlite.ROW then
                total = count_stmt:get_value(0)
            end
            count_stmt:finalize()
        end
    end
    
    db_conn:close()
    
    return {
        logs = logs,
        total = total
    }
end

-- 清理旧日志
function M.clean_old_logs(days)
    days = tonumber(days) or 30
    local cutoff_time = os.time() - (days * 24 * 60 * 60)
    local cutoff_date = os.date("%Y-%m-%d %H:%M:%S", cutoff_time)
    
    local db_conn = db.get_db()
    if not db_conn then return nil, "Database not available" end
    
    local sql = "DELETE FROM logs WHERE created_at < ?"
    local stmt = db_conn:prepare(sql)
    if not stmt then
        db_conn:close()
        return nil, "Failed to prepare statement"
    end
    
    stmt:bind(1, cutoff_date)
    local ret = stmt:step()
    stmt:finalize()
    
    local deleted = db_conn:changes()
    db_conn:close()
    
    if ret ~= sqlite.DONE then
        return nil, "Failed to clean old logs"
    end
    
    -- 记录清理操作
    M.log(M.LEVEL.INFO, "clean_old_logs", {
        days = days,
        cutoff_date = cutoff_date,
        deleted_count = deleted
    })
    
    return deleted
end

-- 自动清理旧日志(30天前)
M.clean_old_logs(30)

return M