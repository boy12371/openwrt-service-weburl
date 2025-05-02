local db = require "project-weburl.db"
local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local http = require "luci.http"
local util = require "luci.util"

module("luci.model.cbi.project-weburl.log", package.seeall)

function index()
    entry({"admin", "services", "project-weburl", "log"}, call("action_log"), _("Logs"), 40).leaf = true
end

function action_log()
    local db_conn = db.init_db()
    if not db_conn then
        http.status(500, "Database Error")
        return
    end

    local page = tonumber(http.formvalue("page")) or 1
    local limit = 20
    local offset = (page - 1) * limit

    -- Get total count
    local total = db_conn:first_row("SELECT COUNT(*) as count FROM logs").count

    -- Get paginated logs
    local stmt = db_conn:prepare("SELECT * FROM logs ORDER BY timestamp DESC LIMIT ? OFFSET ?")
    stmt:bind_values(limit, offset)
    
    local logs = {}
    for row in stmt:nrows() do
        table.insert(logs, row)
    end
    stmt:finalize()
    db_conn:close()

    template.render("project-weburl/log", {
        logs = logs,
        pagination = {
            page = page,
            limit = limit,
            total = total,
            pages = math.ceil(total / limit)
        }
    })
end

function filter_logs(db_conn, action, service_id, date_from, date_to)
    local where = {}
    local params = {}

    if action and action ~= "" then
        table.insert(where, "action = ?")
        table.insert(params, action)
    end

    if service_id and service_id ~= "" then
        table.insert(where, "service_id = ?")
        table.insert(params, tonumber(service_id))
    end

    if date_from and date_from ~= "" then
        table.insert(where, "timestamp >= ?")
        table.insert(params, date_from)
    end

    if date_to and date_to ~= "" then
        table.insert(where, "timestamp <= ?")
        table.insert(params, date_to)
    end

    local where_clause = #where > 0 and " WHERE " .. table.concat(where, " AND ") or ""
    local query = "SELECT * FROM logs" .. where_clause .. " ORDER BY timestamp DESC"

    local stmt = db_conn:prepare(query)
    for i, param in ipairs(params) do
        stmt:bind(i, param)
    end

    local logs = {}
    for row in stmt:nrows() do
        table.insert(logs, row)
    end
    stmt:finalize()

    return logs
end