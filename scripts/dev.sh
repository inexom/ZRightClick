#!/bin/bash
#
# 开发闭环：编译 → 装到 /Applications → 注册并启用 Finder 扩展 → 重启 Finder → 跟日志
#
#   ./scripts/dev.sh          编译 + 安装 + 重启 Finder
#   ./scripts/dev.sh log      只跟日志（另开一个终端窗口用）
#   ./scripts/dev.sh status   查看扩展注册状态
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="ZRightClick"
APP_NAME="ZRightClick.app"
EXT_ID="com.inexom.zrightclick.FinderExtension"
SUBSYSTEM="com.inexom.zrightclick"
BUILD_DIR="$REPO/build"
INSTALL_DIR="/Applications"

follow_log() {
  echo "==> 跟随扩展日志（Ctrl-C 结束）"
  log stream --style compact --level info \
    --predicate "subsystem == \"$SUBSYSTEM\""
}

show_status() {
  echo "==> 已注册的 Finder 扩展"
  pluginkit -m -v -p com.apple.FinderSync || true
  echo
  echo "==> 本扩展状态（+ 表示已启用，- 表示已注册但未启用，空表示没注册上）"
  pluginkit -m -v -i "$EXT_ID" || echo "未找到 $EXT_ID"
}

case "${1:-build}" in
  log)    follow_log; exit 0 ;;
  status) show_status; exit 0 ;;
esac

echo "==> 编译 $SCHEME"
xcodebuild \
  -project "$REPO/ZRightClick.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination 'platform=macOS' \
  CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
  build | tail -20

APP_PATH="$BUILD_DIR/$APP_NAME"
[[ -d "$APP_PATH" ]] || { echo "编译产物不存在: $APP_PATH"; exit 1; }

# Finder 只加载 /Applications 里的扩展，放在 build 目录下往往不生效
echo "==> 安装到 $INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME"
cp -R "$APP_PATH" "$INSTALL_DIR/"

echo "==> 注册并启用扩展"
pluginkit -a "$INSTALL_DIR/$APP_NAME/Contents/PlugIns/ZRightClickFinderExtension.appex" 2>/dev/null || true
pluginkit -e use -i "$EXT_ID" 2>/dev/null || true

echo "==> 重启 Finder"
killall Finder 2>/dev/null || true
sleep 1

show_status
echo
echo "完成。现在去 Finder 里右键试试。看不到菜单就跑 ./scripts/dev.sh log 查日志。"
