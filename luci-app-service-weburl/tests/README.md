# Service WebURL 测试说明

## 测试环境要求
- Lua 5.1+
- luaunit (测试框架)
- SQLite3
- LuCI 基础库

## 安装测试依赖
```bash
opkg update
opkg install lua luaunit lsqlite3
```

## 测试数据库配置
测试使用临时数据库文件：`/tmp/test_service_weburl.db`

## 运行测试
```bash
cd tests
lua test_service_weburl.lua
```

## 测试用例说明
1. 数据库初始化测试
   - 验证数据库文件创建
   - 验证表结构初始化

2. 服务CRUD测试
   - 测试服务创建/读取/更新/删除
   - 验证数据一致性

3. 日志功能测试
   - 测试日志记录
   - 验证日志查询

4. 错误处理测试
   - 测试无效输入处理
   - 验证错误消息

## 测试覆盖率
当前覆盖核心功能：
- 数据库操作: 100%
- 服务管理: 100% 
- 日志记录: 80%