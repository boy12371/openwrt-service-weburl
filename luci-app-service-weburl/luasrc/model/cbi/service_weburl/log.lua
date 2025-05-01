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

-- 记录日志（支持关联服务ID）
function M.log(level, action, data, service_id)
    if not M.LEVEL[level] then
        level = M.LEVEL.INFO
    end
    
    local log_data = {
        level = level,
        action = action,
        data = data
    }
    
    return db.log_action(action, json.encode(log_data), service_id)
end

-- 查询日志（支持多种筛选条件）
function M.query_logs(options)
    options = options or {}
    local where = {}
    local params = {}
    
    -- 按服务ID筛选
    if options.service_id then
        table.insert(where, "service_id = ?")
        table.insert(params, options.service_id)
    end
    
    -- 按操作类型筛选
    if options.action then
        table.insert(where, "action = ?")
        table.insert(params, options.action)
    end
    
    -- 按日志级别筛选
    if options.level then
        table.insert(where, "json_extract(message, '$.level') = ?")
        table.insert(params, options.level)
    end
    
    -- 按时间范围筛选
    if options.start_time then
        table.insert(where, "timestamp >= ?")
        table.insert(params, os.date("%Y-%m-%d %H:%M:%S", options.start_time))
    end
    
    if options.end_time then
        table.insert(where, "timestamp <= ?")
        table.insert(params, os.date("%Y-%m-%d %H:%M:%S", options.end_time))
    end
    
    local where_clause = #where > 0 and "WHERE " .. table.concat(where, " AND ") or ""
    local limit_clause = options.limit and "LIMIT " .. options.limit or ""
    local offset_clause = options.offset and "OFFSET " .. options.offset or ""
    
    -- 获取日志数据
    local result = db.get_logs(options.service_id, options.limit)
    if not result then
        return nil, "Failed to query logs"
    end
    
    -- 处理日志数据
    local logs = {}
    for _, log in ipairs(result) do
        if log.message then
            log.message = json.parse(log.message)
        end
        table.insert(logs, log)
    end
    
    -- 如果需要总数，单独查询
    local total = 0
    if options.need_total then
        local db_conn = db.get_db()
        if db_conn then
            local sql = string.format("SELECT COUNT(*) FROM logs %s", where_clause)
            local stmt = db_conn:prepare(sql)
            if stmt then
                for i, param in ipairs(params) do
                    stmt:bind(i, param)
                end
                
                if stmt:step() == sqlite.ROW then
                    total = stmt:get_value(0)
                end
                stmt:finalize()
            end
            db_conn:close()
        end
    end
    
    return {
        logs = logs,
        total = total
    }
end

-- 清理旧日志（保留最近N天的日志）
function M.clean_old_logs(days)
    days = tonumber(days) or 30
    local cutoff_time = os.time() - (days * 24 * 60 * 60)
    local cutoff_date = os.date("%Y-%m-%d %H:%M:%S", cutoff_time)
    
    local db_conn = db.get_db()
    if not db_conn then return nil, "Database not available" end
    
    local sql = "DELETE FROM logs WHERE timestamp < ?"
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