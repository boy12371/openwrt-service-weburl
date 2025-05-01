# LuCI Service WebURL 应用

![Service WebURL 界面截图](screenshots/service-list.png)

## 功能特性

- **服务管理**
  - 添加/编辑/删除服务
  - 服务URL验证
  - 服务描述支持

- **日志系统**
  - 操作日志记录
  - 时间范围筛选
  - 服务关联日志

- **系统配置**
  - 数据库路径配置
  - 日志保留天数
  - 缓存时间设置

## 安装指南

详见 [INSTALL.md](INSTALL.md)

## 快速开始

1. 访问 `服务 > 服务管理`
2. 添加新服务：
   - 标题: My Service
   - URL: https://example.com
   - 描述: 示例服务

3. 查看操作日志

## 开发指南

### 项目结构

```
luci-app-service-weburl/
├── luasrc/                # Lua 源代码
├── po/                    # 国际化文件
├── root/                  # 系统文件
├── tests/                 # 测试代码
├── Makefile               # 构建配置
└── README.md              # 项目文档
```

### 依赖管理

核心依赖：
- lsqlite3
- luci-lib-json
- luci-base

### 测试运行

```bash
cd tests
lua test_service_weburl.lua
```

## 贡献指南

1. Fork 项目仓库
2. 创建特性分支 (`git checkout -b feature`)
3. 提交更改 (`git commit -am 'Add feature'`)
4. 推送分支 (`git push origin feature`)
5. 创建 Pull Request

## 许可证

MIT 许可证