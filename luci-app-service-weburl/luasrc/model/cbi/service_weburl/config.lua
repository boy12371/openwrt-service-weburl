local uci = require "luci.model.uci".cursor()

module("luci.model.cbi.service_weburl.config", package.seeall)

-- 默认配置
local DEFAULT_CONFIG = {
    db_path = "/etc/config/service_weburl.db",
    db_perms = 600,
    log_level = "info"
}

-- 获取配置
function get_config()
    local config = {}
    uci:foreach("service_weburl", "service_weburl",
        function(section)
            config.db_path = section.db_path or DEFAULT_CONFIG.db_path
            config.db_perms = tonumber(section.db_perms) or DEFAULT_CONFIG.db_perms
            config.log_level = section.log_level or DEFAULT_CONFIG.log_level
        end)
    
    return setmetatable(config, {__index = DEFAULT_CONFIG})
end

-- 初始化UCI配置
function init_uci_config()
    if not uci:get("service_weburl", "service_weburl") then
        uci:section("service_weburl", "service_weburl", "service_weburl", {
            db_path = DEFAULT_CONFIG.db_path,
            db_perms = DEFAULT_CONFIG.db_perms,
            log_level = DEFAULT_CONFIG.log_level
        })
        uci:save("service_weburl")
        uci:commit("service_weburl")
    end
end

return _M