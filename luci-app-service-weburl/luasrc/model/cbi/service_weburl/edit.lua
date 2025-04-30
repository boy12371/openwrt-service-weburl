local db = require "service_weburl.db"
local m = SimpleForm("edit", translate("Edit Service"))
m.submit = translate("Save Changes")
m.reset = false

-- 从 URL 参数中获取服务 ID
local service_id = luci.http.formvalue("id")
if not service_id or not tonumber(service_id) then
    luci.http.redirect(luci.dispatcher.build_url("admin/services/service_weburl"))
    return
end

-- 查询服务数据
local service = db.get_service_by_id(service_id)
if not service then
    luci.http.redirect(luci.dispatcher.build_url("admin/services/service_weburl"))
    return
end

-- 表单字段
local title = m:field(Value, "title", translate("Title"))
title.required = true
title.value = service.title

-- 自定义URL验证函数
local function validate_url(url)
    if not url then return false end
    -- 基本URL格式验证
    if not url:match("^https?://[%w-_%.]+") then
        return false, translate("Invalid URL format")
    end
    -- 长度限制(与数据库一致)
    if #url > 1024 then
        return false, translate("URL too long (max 1024 characters)")
    end
    return true
end

local url = m:field(Value, "url", translate("URL"))
url.required = true
url.datatype = "string"
url.validate = validate_url
url.value = service.url

local title = m:field(Value, "title", translate("Title"))
title.required = true
title.datatype = "string"
title.maxlength = 255
title.value = service.title

local desc = m:field(TextValue, "description", translate("Description"))
desc.rows = 3
desc.maxlength = 1024
desc.value = service.description

-- 处理表单提交
function m:handle(values)
    if not values then return true end
    
    -- 验证输入
    if not values.title or #values.title == 0 then
        m.message = translate("Title is required")
        return false
    end
    
    local ok, err = validate_url(values.url)
    if not ok then
        m.message = err or translate("Invalid URL")
        return false
    end
    
    -- 更新服务
    local success, err = db.update_service(service_id, values.title, values.url, values.description)
    if not success then
        m.message = translate("Failed to update service: ") .. (err or "")
        return false
    end
    
    m.message = translate("Service updated successfully")
    luci.http.redirect(luci.dispatcher.build_url("admin/services/service_weburl"))
    return true
end

return m