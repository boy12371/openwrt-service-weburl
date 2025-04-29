local db = require "service_weburl.db"
local m = SimpleForm("add", translate("Add New Service"))  -- 标题修正

m.submit = translate("Submit")
m.reset = false

local title = m:field(Value, "title", translate("Title"))
title.required = true

local url = m:field(Value, "url", translate("URL"))
url.required = true
url.datatype = "url"

local desc = m:field(TextValue, "description", translate("Description"))
desc.rows = 3

function m:handle(values)
    db.add_service(values.title, values.url, values.description)
    luci.http.redirect(luci.dispatcher.build_url("admin/services/service_weburl"))
    return true
end

return m