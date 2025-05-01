# LuCI Service WebURL 应用安装指南

## 系统要求
- OpenWrt 18.06 或更高版本
- 已安装 LuCI 界面
- SQLite3 支持

## 安装步骤

1. 安装依赖：
   ```bash
   opkg update
   opkg install lsqlite3 luci-base luci-lib-json
   ```

2. 安装应用：
   ```bash
   # 方法1：使用opkg安装IPK包
   opkg install luci-app-service-weburl_1.0_all.ipk
   
   # 方法2：手动安装
   cp -r luci-app-service-weburl /usr/lib/lua/luci/
   ```

3. 初始化数据库：
   ```bash
   touch /var/lib/service_weburl.db
   chmod 0644 /var/lib/service_weburl.db
   ```

4. 重启服务：
   ```bash
   /etc/init.d/rpcd restart
   ```

## 配置说明

主配置文件路径：`/etc/config/service_weburl`

默认配置：
```bash
config main
    option enabled '1'
    option db_path '/var/lib/service_weburl.db'
    option log_retention_days '30'
```

## 访问方式
1. 登录 LuCI 界面
2. 导航至：服务 > 服务管理

## 测试验证
1. 添加新服务
2. 编辑现有服务
3. 删除服务
4. 检查操作日志
5. 验证搜索功能