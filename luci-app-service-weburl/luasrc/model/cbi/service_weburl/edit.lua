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

local url = m:field(Value, "url", translate("URL"))
url.required = true
url.datatype = "url"
url.value = service.url

local desc = m:field(TextValue, "description", translate("Description"))
desc.rows = 3
desc.value = service.description

-- 处理表单提交
function m:handle(values)
    if values then
        db.update_service(service_id, values.title, values.url, values.description)
        luci.http.redirect(luci.dispatcher.build_url("admin/services/service_weburl"))
    end
    return true
end

return m
