m = Map("service_weburl")
m.title = translate("WebURL Service")
m.description = translate("<a href=\"https://github.com/messense/service_weburl\" target=\"_blank\">Project GitHub URL</a>")

m:section(SimpleSection).template = "service_weburl/status"

e = m:section(TypedSection, "server")
e.anonymous = true

enable = e:option(Flag, "enable", translate("Enable"))
enable.rmempty = false

refresh_token = e:option(Value, "refresh_token", translate("Refresh Token"))

root = e:option(Value, "root", translate("Root Directory"))
root.description = translate("Restrict access to a folder, defaults to / which means no restrictions")
root.default = "/"

host = e:option(Value, "host", translate("Host"))
host.default = "0.0.0.0"
host.datatype = "ipaddr"

port = e:option(Value, "port", translate("Port"))
port.default = "8080"
port.datatype = "port"

tls_cert = e:option(Value, "tls_cert", translate("TLS certificate file path"))
tls_key = e:option(Value, "tls_key", translate("TLS private key file path"))

auth_user = e:option(Value, "auth_user", translate("Username"))
auth_password = e:option(Value, "auth_password", translate("Password"))
auth_password.password = true

read_buffer_size = e:option(Value, "read_buffer_size", translate("Read Buffer Size"))
read_buffer_size.default = "10485760"
read_buffer_size.datatype = "uinteger"

prefer_http_download = e:option(Flag, "prefer_http_download", translate("Prefer HTTP Download"))
prefer_http_download.description = translate("Prefer downloading files using HTTP instead of HTTPS protocol")
prefer_http_download.rmempty = false

redirect = e:option(Flag, "redirect", translate("Enable 302 Redirect"))
redirect.description = translate("Enable 302 redirect when possible")
redirect.rmempty = false

upload_buffer_size = e:option(Value, "upload_buffer_size", translate("Upload Buffer Size"))
upload_buffer_size.default = "16777216"
upload_buffer_size.datatype = "uinteger"

skip_upload_same_size = e:option(Flag, "skip_upload_same_size", translate("Skip uploading same size files"))
skip_upload_same_size.description = translate("Reduce the upload traffic by skipping uploading files with the same size")
skip_upload_same_size.rmempty = false

cache_size = e:option(Value, "cache_size", translate("Cache Size"))
cache_size.default = "1000"
cache_size.datatype = "uinteger"

cache_ttl = e:option(Value, "cache_ttl", translate("Cache Expiration Time (seconds)"))
cache_ttl.default = "600"
cache_ttl.datatype = "uinteger"

no_trash = e:option(Flag, "no_trash", translate("Delete file permanently instead of trashing"))
no_trash.rmempty = false

read_only = e:option(Flag, "read_only", translate("Enable read only mode"))
read_only.description = translate("Disallow upload, modify and delete file operations")
read_only.rmempty = false

debug = e:option(Flag, "debug", translate("Debug Mode"))
debug.rmempty = false

return m