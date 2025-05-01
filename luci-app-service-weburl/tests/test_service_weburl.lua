local luaunit = require("luaunit")
local db = require("luci.model.cbi.service_weburl.db")
local service = require("luci.model.cbi.service_weburl.service")
local log = require("luci.model.cbi.service_weburl.log")

TestServiceWebURL = {}

function TestServiceWebURL:setUp()
    -- 初始化测试数据库
    os.execute("rm -f /tmp/test_service_weburl.db")
    db.DB_PATH = "/tmp/test_service_weburl.db"
    db.init_db()
end

function TestServiceWebURL:test_db_initialization()
    -- 验证数据库初始化
    local db_conn = db.get_db()
    luaunit.assertNotNil(db_conn)
    db_conn:close()
end

function TestServiceWebURL:test_service_crud()
    -- 测试服务创建
    local service_id = service.add_service("Test", "http://example.com", "Test description")
    luaunit.assertNotNil(service_id)
    
    -- 测试服务读取
    local services = service.get_services()
    luaunit.assertEquals(#services, 1)
    luaunit.assertEquals(services[1].title, "Test")
    
    -- 测试服务更新
    local ok = service.update_service(service_id, "Updated", "http://updated.com", "Updated desc")
    luaunit.assertTrue(ok)
    
    -- 验证更新
    local updated = service.get_service(service_id)
    luaunit.assertEquals(updated.title, "Updated")
    
    -- 测试服务删除
    ok = service.delete_service(service_id)
    luaunit.assertTrue(ok)
    
    -- 验证删除
    services = service.get_services()
    luaunit.assertEquals(#services, 0)
end

function TestServiceWebURL:test_logging()
    -- 测试日志记录
    local ok = log.log(log.LEVEL.INFO, "test_action", {key="value"}, 1)
    luaunit.assertTrue(ok)
    
    -- 验证日志
    local logs = log.query_logs({service_id=1})
    luaunit.assertEquals(#logs.logs, 1)
    luaunit.assertEquals(logs.logs[1].action, "test_action")
end

function TestServiceWebURL:test_error_handling()
    -- 测试无效服务ID
    local service = service.get_service(999)
    luaunit.assertNil(service)
    
    -- 测试无效URL
    local ok, err = service.add_service("Test", "invalid_url", "desc")
    luaunit.assertFalse(ok)
    luaunit.assertStrContains(err, "URL格式")
end

-- 运行测试
local runner = luaunit.LuaUnit.new()
os.exit(runner:runSuite())