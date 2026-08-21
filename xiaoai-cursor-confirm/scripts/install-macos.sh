#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build/release"
APP_NAME="小爱确认"
BUNDLE="$ROOT/dist/${APP_NAME}.app"
BIN_NAME="XiaoAiCursorConfirm"

echo "→ 编译 macOS 小爱确认（需要 Xcode / Swift 5.9+）"
cd "$ROOT"
swift build -c release --product "$BIN_NAME"

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp "$BUILD_DIR/$BIN_NAME" "$BUNDLE/Contents/MacOS/$BIN_NAME"
cp "$ROOT/Sources/XiaoAiCursorConfirm/Resources/Info.plist" "$BUNDLE/Contents/Info.plist"

cat > "$BUNDLE/Contents/PkgInfo" <<'EOF'
APPL????
EOF

chmod +x "$BUNDLE/Contents/MacOS/$BIN_NAME" \
  "$ROOT/cli/xiaoai-cursor.mjs" \
  "$ROOT/mcp/server.mjs"

echo "→ 已生成 $BUNDLE"
echo "   可拖到 /Applications，然后在 Cursor 里配置 mcp/server.mjs"
echo "   CLI: node $ROOT/cli/xiaoai-cursor.mjs health"
