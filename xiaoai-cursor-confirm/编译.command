#!/bin/bash
# 双击此文件即可在 Mac 上编译并打开「小爱确认」
cd "$(dirname "$0")"
chmod +x scripts/install-macos.sh
./scripts/install-macos.sh
echo
read -r -p "按回车键关闭窗口…"
