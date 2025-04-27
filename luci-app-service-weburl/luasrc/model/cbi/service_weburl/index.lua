m = Map("service_weburl")
m.title = translate("Service WebUrl")
m.description = translate("<a href=\"https://github.com/messense/service-weburl\" target=\"_blank\">Project GitHub URL</a>")

m:section(SimpleSection).template = "service-weburl/index"

return m
