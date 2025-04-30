local db = require "service_weburl.db"
local m = SimpleForm("add", translate("Add New Service"))

m.submit = translate("Submit")
m.reset = false

-- 自定义URL验证函数(与edit.lua保持一致)
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

local title = m:field(Value, "title", translate("Title"))
title.required = true
title.datatype = "string"
title.maxlength = 255

local url = m:field(Value, "url", translate("URL"))
url.required = true
url.datatype = "string"
url.validate = validate_url

local desc = m:field(TextValue, "description", translate("Description"))
desc.rows = 3
desc.maxlength = 1024

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
    
    -- 添加服务
    local success, err = db.add_service(values.title, values.url, values.description)
    if not success then
        m.message = translate("Failed to add service: ") .. (err or "")
        return false
    end
    
    m.message = translate("Service added successfully")
    luci.http.redirect(luci.dispatcher.build_url("admin/services/service_weburl"))
    return true
end

return m