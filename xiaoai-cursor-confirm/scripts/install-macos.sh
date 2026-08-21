#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build/release"
APP_NAME="小爱确认"
BUNDLE="$ROOT/dist/${APP_NAME}.app"
BIN_NAME="XiaoAiCursorConfirm"

if [[ "$(uname -s)" != "Darwin" ]]; then
  cat <<'EOF'
这个脚本只能在 macOS 上编译。

请在 Mac 的「终端」里执行：

  git clone -b cursor/macos-xiaoai-confirm-29b2 https://github.com/AssassinBar/Cloudflare-R2-oss.git
  cd Cloudflare-R2-oss/xiaoai-cursor-confirm
  ./scripts/install-macos.sh
  open "dist/小爱确认.app"

EOF
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "未找到 swift。请先安装 Xcode 或命令行工具："
  echo "  xcode-select --install"
  echo "或从 App Store 安装 Xcode，打开一次并同意许可。"
  exit 1
fi

if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
  echo "若编译失败，请打开一次 Xcode 并完成许可协议。"
fi

echo "→ Swift $(swift --version | head -n 1)"
echo "→ 编译 $APP_NAME（约 1–3 分钟）"
cd "$ROOT"
swift build -c release --product "$BIN_NAME" -Xswiftc -parse-as-library

BIN_PATH="$(swift build -c release --product "$BIN_NAME" --show-bin-path)/$BIN_NAME"
if [[ ! -x "$BIN_PATH" ]]; then
  BIN_PATH="$BUILD_DIR/$BIN_NAME"
fi
if [[ ! -x "$BIN_PATH" ]]; then
  echo "编译成功但找不到可执行文件：$BIN_PATH"
  exit 1
fi

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp "$BIN_PATH" "$BUNDLE/Contents/MacOS/$BIN_NAME"
cp "$ROOT/Sources/XiaoAiCursorConfirm/Resources/Info.plist" "$BUNDLE/Contents/Info.plist"
printf 'APPL????' > "$BUNDLE/Contents/PkgInfo"
chmod +x "$BUNDLE/Contents/MacOS/$BIN_NAME" \
  "$ROOT/cli/xiaoai-cursor.mjs" \
  "$ROOT/mcp/server.mjs" \
  "$ROOT/scripts/install-macos.sh"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$BUNDLE" >/dev/null 2>&1 || true
fi
xattr -cr "$BUNDLE" >/dev/null 2>&1 || true

echo
echo "→ 已生成：$BUNDLE"
echo "→ 正在打开应用…"
open "$BUNDLE"

echo
echo "接下来："
echo "  1. 在测试对接里扫码登录小米账号"
echo "  2. 选择小爱音箱，点「试听播报」"
echo "  3. 可选：把 App 拖到 /Applications"
echo "  CLI: node $ROOT/cli/xiaoai-cursor.mjs health"
