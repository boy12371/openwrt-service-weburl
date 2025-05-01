#!/bin/sh

# 项目完整性验证脚本

echo "开始验证项目完整性..."

# 1. 检查文件权限
echo "检查文件权限..."
find . -type f -not -perm 0644 -exec ls -l {} \;
find . -type d -not -perm 0755 -exec ls -ld {} \;

# 2. 运行测试
echo "运行单元测试..."
cd tests && lua test_service_weburl.lua
cd ..

# 3. 检查文档完整性
echo "检查文档..."
[ -f README.md ] || echo "缺少README.md"
[ -f INSTALL.md ] || echo "缺少INSTALL.md"
[ -f tests/README.md ] || echo "缺少tests/README.md"

# 4. 验证国际化文件
echo "检查国际化文件..."
[ -f po/zh_Hans/service_weburl.po ] || echo "缺少中文翻译文件"

# 5. 构建测试
echo "测试构建流程..."
make clean
make package/luci-app-service-weburl/compile V=99

echo "验证完成"