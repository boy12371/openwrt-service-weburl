# LuCI Service WebURL

一个用于管理服务网址的 OpenWrt LuCI 应用。

## 功能特点

- 服务网址的添加、编辑、删除管理
- 支持服务描述和链接展示
- 操作日志记录和查看
- 响应式界面设计
- 中文界面支持

## 安装要求

- OpenWrt 系统
- LuCI Web 界面
- SQLite3 支持

## 依赖项

- luci-base
- luci-compat
- sqlite3

## 安装方法

### 从源码编译

1. 将代码复制到 OpenWrt SDK 的 package 目录：

```bash
git clone https://github.com/your-username/luci-app-service-weburl.git package/luci-app-service-weburl
```

2. 选择要编译的软件包：

```bash
make menuconfig
# 找到 LuCI -> Applications -> luci-app-service-weburl
```

3. 编译软件包：

```bash
make package/luci-app-service-weburl/compile V=s
```

### 直接安装 IPK

1. 下载 IPK 文件
2. 通过 LuCI 界面上传并安装
3. 或者使用 opkg 命令安装：

```bash
opkg install luci-app-service-weburl_1.0.0_all.ipk
```

## 使用说明

1. 安装完成后，在 LuCI 界面的"服务"菜单下可以找到"服务网址"选项
2. 界面包含三个主要部分：
   - 服务列表：显示所有已添加的服务
   - 添加服务：添加新的服务网址
   - 操作日志：查看所有操作记录

### 添加服务

1. 点击"添加新服务"按钮
2. 填写服务信息：
   - 标题（必填）
   - 网址（必填，需以 http:// 或 https:// 开头）
   - 描述（可选）
3. 点击"保存"按钮完成添加

### 编辑服务

1. 在服务列表中找到要编辑的服务
2. 点击"编辑"按钮
3. 修改相关信息
4. 点击"保存"按钮完成编辑

### 删除服务

1. 在服务列表中找到要删除的服务
2. 点击"删除"按钮
3. 确认删除操作

### 查看日志

1. 点击"日志"标签页
2. 可以查看所有操作记录
3. 支持按操作类型筛选日志

## 数据存储

- 服务数据存储在 SQLite 数据库中
- 数据库文件位置：/etc/service_weburl/data.db
- 配置文件位置：/etc/config/service_weburl

## 故障排除

1. 如果界面无法加载：
   - 检查 service_weburl 服务是否正在运行
   - 检查数据库文件权限

2. 如果无法添加服务：
   - 确保填写了必要的信息
   - 检查网址格式是否正确

3. 如果日志无法显示：
   - 检查数据库文件权限
   - 确保数据库表结构正确

## 许可证

本项目采用 MIT 许可证。

## 技术支持

如有问题，请提交 Issue 到项目仓库。