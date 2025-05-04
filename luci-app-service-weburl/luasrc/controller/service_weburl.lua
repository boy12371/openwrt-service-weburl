module("luci.controller.service_weburl", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/service_weburl") then return end

	local page
	page = entry({ "admin", "services", "service_weburl" }, alias("admin", "services", "service_weburl", "client"),
		_("WebURL Service"), 10) -- 首页
	page.dependent = true
	page.acl_depends = { "luci-app-service-weburl" }

	entry({ "admin", "services", "service_weburl", "client" }, cbi("service_weburl/client"), _("Settings"), 10).leaf = true -- 客户端配置
	entry({ "admin", "services", "service_weburl", "log" }, form("service_weburl/log"), _("Log"), 30).leaf = true -- 日志页面

	entry({ "admin", "services", "service_weburl", "status" }, call("action_status")).leaf = true -- 运行状态
	entry({ "admin", "services", "service_weburl", "logtail" }, call("action_logtail")).leaf = true -- 日志采集
	entry({ "admin", "services", "service_weburl", "invalidate-cache" }, call("action_invalidate_cache")).leaf = true -- 清除缓存
end

function action_status()
	local e = {}
	e.running = luci.sys.call("pidof service_weburl >/dev/null") == 0
	e.application = luci.sys.exec("service_weburl --version")
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function action_logtail()
	local fs = require "nixio.fs"
	local log_path = "/var/log/service_weburl.log"
	local e = {}
	e.running = luci.sys.call("pidof service_weburl >/dev/null") == 0
	if fs.access(log_path) then
		e.log = luci.sys.exec("tail -n 100 %s | sed 's/\\x1b\\[[0-9;]*m//g'" % log_path)
	else
		e.log = ""
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function action_invalidate_cache()
	local e = {}
	e.ok = luci.sys.call("kill -HUP `pidof service_weburl`") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

-- 服务管理API
entry({"admin", "services", "service_weburl", "services"}, call("action_list_services")).leaf = true  -- GET 获取服务列表
entry({"admin", "services", "service_weburl", "services", "create"}, call("action_add_service")).leaf = true  -- POST 创建服务
entry({"admin", "services", "service_weburl", "services", ":id"}, call("action_update_service")).leaf = true  -- PUT 更新服务
entry({"admin", "services", "service_weburl", "services", ":id"}, call("action_delete_service")).leaf = true  -- DELETE 删除服务

function action_list_services()
	local uci = require "luci.model.uci".cursor()
	local e = {services = {}}

	uci:foreach("service_weburl", "service", function(s)
		table.insert(e.services, {
			id = s[".name"],
			title = s.title,
			url = s.url,
			description = s.description
		})
	end)

	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function action_add_service()
	local uci = require "luci.model.uci".cursor()
	local http = luci.http
	local e = {success = false}

	local data = http.content()
	if data then
		local service = luci.jsonc.parse(data)
		if service and service.title and service.url then
			local id = "service_" .. os.time()
			uci:section("service_weburl", "service", id, {
				title = service.title,
				url = service.url,
				description = service.description or ""
			})

			if uci:save() and uci:commit() then
				e.success = true
				e.id = id
			else
				e.error = "Failed to save configuration"
			end
		else
			e.error = "Invalid service data"
		end
	else
		e.error = "No data received"
	end

	http.prepare_content("application/json")
	http.write_json(e)
end

function action_update_service(id)
	local uci = require "luci.model.uci".cursor()
	local http = luci.http
	local e = {success = false}

	if id then
		local data = http.content()
		if data then
			local service = luci.jsonc.parse(data)
			if service and service.title and service.url then
				if uci:get("service_weburl", id) then
					uci:set("service_weburl", id, "title", service.title)
					uci:set("service_weburl", id, "url", service.url)
					uci:set("service_weburl", id, "description", service.description or "")

					if uci:save() and uci:commit() then
						e.success = true
					else
						e.error = "Failed to save configuration"
					end
				else
					e.error = "Service not found"
				end
			else
				e.error = "Invalid service data"
			end
		else
			e.error = "No data received"
		end
	else
		e.error = "Missing service ID"
	end

	http.prepare_content("application/json")
	http.write_json(e)
end

function action_delete_service(id)
	local uci = require "luci.model.uci".cursor()
	local http = luci.http
	local e = {success = false}

	if id then
		if uci:get("service_weburl", id) then
			uci:delete("service_weburl", id)
			if uci:save() and uci:commit() then
				e.success = true
			else
				e.error = "Failed to save configuration"
			end
		else
			e.error = "Service not found"
		end
	else
		e.error = "Missing service ID"
	end

	http.prepare_content("application/json")
	http.write_json(e)
end