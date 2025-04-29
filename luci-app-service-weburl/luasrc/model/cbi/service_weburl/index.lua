m = Map("service_weburl")
local db = require "service_weburl.db"

m.title = translate("Service WebUrl")
m.description = translate("Service Management Dashboard")

local services = db.query_services()

local section = m:section(SimpleSection)
section.template = "service_weburl/index"
section.services = services

return m
