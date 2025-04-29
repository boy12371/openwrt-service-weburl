local m = Map("service_weburl", translate("Application Settings"))  -- 关联 UCI 配置
m.description = translate("Configure global settings for Service WebUrl.")

-- 启用服务开关
local enable = m:field(Flag, "enabled", translate("Enable Service"))
enable.default = true
enable.rmempty = false

-- 日志文件路径
local log_path = m:field(Value, "log_path", translate("Log File Path"))
log_path.default = "/var/log/service_weburl.log"
log_path.datatype = "filepath"

-- 日志保留天数
local log_retention = m:field(ListValue, "log_retention", translate("Log Retention Days"))
log_retention:value("7", "7 Days")
log_retention:value("30", "30 Days")
log_retention:value("90", "90 Days")
log_retention.default = "7"

-- 提交处理
function m:handle(form, values)
    if values then
        -- 保存配置到 UCI
        self.uci:commit("service_weburl")
    end
    return true
end

return m
