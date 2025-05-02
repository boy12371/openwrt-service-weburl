module("luci.model.service_weburl.log", package.seeall)

local db = require "service_weburl.db"
local util = require "luci.util"
local sys = require "luci.sys"

-- 获取日志列表
function get_logs(page, limit)
    page = tonumber(page) or 1
    limit = tonumber(limit) or 20
    local offset = (page - 1) * limit
    
    local db_conn = db.init_db()
    if not db_conn then
        return nil, "Failed to connect to database"
    end
    
    -- 获取总数
    local total = 0
    local stmt = db_conn:prepare("SELECT COUNT(*) FROM logs")
    if stmt then
        if stmt:step() == sqlite3.ROW then
            total = stmt:get_value(0)
        end
        stmt:finalize()
    end
    
    -- 获取日志数据
    local logs = {}
    stmt = db_conn:prepare(string.format(
        "SELECT * FROM logs ORDER BY timestamp DESC LIMIT %d OFFSET %d",
        limit, offset
    ))
    
    if stmt then
        while stmt:step() == sqlite3.ROW do
            table.insert(logs, {
                id = stmt:get_value(0),
                action = stmt:get_value(1),
                message = stmt:get_value(2),
                service_id = stmt:get_value(3),
                timestamp = stmt:get_value(4)
            })
        end
        stmt:finalize()
    end
    
    db_conn:close()
    return logs, total
end

-- 记录日志
function log_action(action, message, service_id)
    local db_conn = db.init_db()
    if not db_conn then
        return nil, "Failed to connect to database"
    end
    
    -- 输入验证
    if not action or type(action) ~= "string" or #action > 50 then
        return nil, "Invalid action (max 50 chars)"
    end
    
    message = message and #message > 0 and message or nil
    service_id = service_id and tonumber(service_id) or nil
    
    local success, err = db.log_action(db_conn, action, message, service_id)
    db_conn:close()
    
    return success, err
end

-- 清除旧日志
function cleanup_logs(days_to_keep)
    days_to_keep = tonumber(days_to_keep) or 30
    local cutoff = os.time() - (days_to_keep * 86400)
    
    local db_conn = db.init_db()
    if not db_conn then
        return nil, "Failed to connect to database"
    end
    
    local stmt = db_conn:prepare("DELETE FROM logs WHERE timestamp < ?")
    if not stmt then
        db_conn:close()
        return nil, "Failed to prepare cleanup statement"
    end
    
    stmt:bind_values(cutoff)
    local success = stmt:step()
    stmt:finalize()
    db_conn:close()
    
    return success
end

return _M