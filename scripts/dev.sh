#!/bin/bash
#
# 开发闭环：编译 → 装到 /Applications → 重新注册扩展 → 启动宿主 App → 重启 Finder → 查状态
#
#   ./scripts/dev.sh          完整一轮（Release）
#   ./scripts/dev.sh debug    使用 Debug，便于调试
#   ./scripts/dev.sh log      实时跟日志（另开终端窗口）
#   ./scripts/dev.sh logs     回看最近 5 分钟日志
#   ./scripts/dev.sh status   查看扩展注册状态
#
# 这里每一步都对应一个踩过的坑，别随手删：
#   1. 必须装到 /Applications：注册在 build/ 目录下时 pluginkit 认不出它是 FinderSync 扩展
#   2. 必须先注销旧路径：同一个 bundle id 注册两份会互相顶掉
#   3. 必须启动宿主 App 一次：LaunchServices 没登记过，扩展不会被 Finder 拉起
#   4. 必须在注册之后才重启 Finder：顺序反了扩展进程不会启动
#   5. 查日志要带 --info：info 级别日志默认不进持久存储，log show 不加参数看不到
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="ZRightClick"
APP_NAME="ZRightClick.app"
APPEX_NAME="ZRightClickFinderExtension.appex"
EXT_ID="com.inexom.zrightclick.FinderExtension"
SUBSYSTEM="com.inexom.zrightclick"
BUILD_DIR="$REPO/build"
INSTALL_DIR="/Applications"
APPEX_INSTALLED="$INSTALL_DIR/$APP_NAME/Contents/PlugIns/$APPEX_NAME"
CONFIGURATION="Release"

case "${1:-release}" in
  build|release)
    ;;
  debug)
    CONFIGURATION="Debug"
    ;;
  log)
    echo "==> 实时跟随扩展日志（Ctrl-C 结束）"
    exec log stream --style compact --level info --predicate "subsystem == \"$SUBSYSTEM\""
    ;;
  logs)
    echo "==> 最近 5 分钟扩展日志"
    exec log show --last 5m --info --style compact --predicate "subsystem == \"$SUBSYSTEM\""
    ;;
  status)
    echo "==> 系统里所有 FinderSync 扩展（+ 已启用 / - 已注册未启用）"
    pluginkit -m -v -p com.apple.FinderSync
    echo
    echo "==> 扩展进程"
    ps aux | grep "$APPEX_NAME" | grep -v grep || echo "（未运行）"
    exit 0
    ;;
  *)
    echo "用法：$0 [release|debug|status|log|logs]" >&2
    exit 2
    ;;
esac

echo "==> 编译 $SCHEME ($CONFIGURATION)"
BUILD_LOG="$(mktemp -t zrightclick-build)"
trap 'rm -f "$BUILD_LOG"' EXIT
if ! xcodebuild \
  -project "$REPO/ZRightClick.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
  build >"$BUILD_LOG" 2>&1; then
  cat "$BUILD_LOG"
  exit 1
fi
grep -E "error:|warning: [^M]|BUILD SUCCEEDED|BUILD FAILED" "$BUILD_LOG" || true

[[ -d "$BUILD_DIR/$APP_NAME" ]] || { echo "编译产物不存在，先看上面的报错"; exit 1; }

echo "==> 注销旧注册"
pluginkit -r "$BUILD_DIR/$APP_NAME/Contents/PlugIns/$APPEX_NAME" 2>/dev/null || true
pluginkit -r "$APPEX_INSTALLED" 2>/dev/null || true

echo "==> 停止旧版本"
pkill -x ZRightClick 2>/dev/null || true
pkill -x ZRightClickFinderExtension 2>/dev/null || true

echo "==> 安装到 $INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME"
cp -R "$BUILD_DIR/$APP_NAME" "$INSTALL_DIR/"

echo "==> 注册并启用扩展"
pluginkit -a "$APPEX_INSTALLED"
open -a "$INSTALL_DIR/$APP_NAME"
sleep 2
pluginkit -e use -i "$EXT_ID"

echo "==> 重启 Finder"
killall Finder 2>/dev/null || true
sleep 4

echo
echo "==> 扩展状态"
pluginkit -m -v -i "$EXT_ID" || echo "没注册上"
ps aux | grep "$APPEX_NAME" | grep -v grep >/dev/null \
  && echo "扩展进程已启动" \
  || echo "扩展进程未启动（这是问题信号）"

echo
echo "==> 启动日志"
log show --last 1m --info --style compact --predicate "subsystem == \"$SUBSYSTEM\"" | tail -12

echo
echo "去 Finder 里右键试试。日志：./scripts/dev.sh log"
