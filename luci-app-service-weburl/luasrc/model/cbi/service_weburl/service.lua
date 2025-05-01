local db = require "luci.model.cbi.service_weburl.db"
local log = require "luci.model.cbi.service_weburl.log"
local util = require "luci.util"
local json = require "luci.jsonc"

local M = {}

-- 缓存表
local cache = {
    services = nil,
    last_update = 0,
    cache_time = 300 -- 5分钟缓存
}

-- 验证URL格式
local function validate_url(url)
    if not url or url == "" then
        return false, "URL不能为空"
    end
    
    -- 简单URL格式验证
    if not url:match("^https?://[%w-_%.%?%.:/%+=&]+$") then
        return false, "URL格式不正确"
    end
    
    return true
end

-- 验证服务标题
local function validate_title(title)
    if not title or title == "" then
        return false, "标题不能为空"
    end
    
    if #title > 100 then
        return false, "标题长度不能超过100个字符"
    end
    
    return true
end

-- 验证服务描述
local function validate_description(desc)
    if desc and #desc > 500 then
        return false, "描述长度不能超过500个字符"
    end
    return true
end

-- 添加服务
function M.add_service(title, url, description)
    -- 输入验证
    local valid, err = validate_title(title)
    if not valid then return nil, err end
    
    valid, err = validate_url(url)
    if not valid then return nil, err end
    
    valid, err = validate_description(description)
    if not valid then return nil, err end
    
    -- 添加到数据库
    local service_id, err = db.add_service(title, url, description)
    if not service_id then
        log.log(log.LEVEL.ERROR, "add_service_failed", {
            title = title,
            url = url,
            error = err
        })
        return nil, err
    end
    
    -- 清除缓存
    cache.services = nil
    
    -- 日志已在db.add_service中记录
    return service_id
end

-- 获取所有服务
function M.get_services(force_refresh)
    -- 检查缓存
    if not force_refresh and cache.services and 
       os.time() - cache.last_update < cache.cache_time then
        return cache.services
    end
    
    -- 从数据库获取
    local services, err = db.get_services()
    if not services then
        log.log(log.LEVEL.ERROR, "get_services_failed", {
            error = err
        })
        return nil, err
    end
    
    -- 更新缓存
    cache.services = services
    cache.last_update = os.time()
    
    return services
end

-- 获取单个服务
function M.get_service(id)
    local services, err = M.get_services()
    if not services then return nil, err end
    
    for _, service in ipairs(services) do
        if tonumber(service.id) == tonumber(id) then
            return service
        end
    end
    
    return nil, "服务不存在"
end

-- 更新服务
function M.update_service(id, title, url, description)
    -- 输入验证
    local valid, err = validate_title(title)
    if not valid then return nil, err end
    
    valid, err = validate_url(url)
    if not valid then return nil, err end
    
    valid, err = validate_description(description)
    if not valid then return nil, err end
    
    -- 检查服务是否存在
    local service = M.get_service(id)
    if not service then
        return nil, "服务不存在"
    end
    
    -- 更新数据库
    local ok, err = db.update_service(id, title, url, description)
    if not ok then
        log.log(log.LEVEL.ERROR, "update_service_failed", {
            id = id,
            title = title,
            url = url,
            error = err
        })
        return nil, err
    end
    
    -- 清除缓存
    cache.services = nil
    
    -- 日志已在db.update_service中记录
    return true
end

-- 删除服务
function M.delete_service(id)
    -- 检查服务是否存在
    local service = M.get_service(id)
    if not service then
        return nil, "服务不存在"
    end
    
    -- 从数据库删除
    local ok, err = db.delete_service(id)
    if not ok then
        log.log(log.LEVEL.ERROR, "delete_service_failed", {
            id = id,
            error = err
        })
        return nil, err
    end
    
    -- 清除缓存
    cache.services = nil
    
    -- 日志已在db.delete_service中记录
    return true
end

-- 搜索服务
function M.search_services(keyword)
    local services, err = M.get_services()
    if not services then return nil, err end
    
    local results = {}
    keyword = keyword and keyword:lower() or ""
    
    for _, service in ipairs(services) do
        if (service.title and service.title:lower():find(keyword, 1, true)) or
           (service.description and service.description:lower():find(keyword, 1, true)) then
            table.insert(results, service)
        end
    end
    
    return results
end

return M