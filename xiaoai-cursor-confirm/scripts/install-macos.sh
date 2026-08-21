#!/bin/bash
set -e

if [ -z "${BASH_VERSION:-}" ]; then
  exec /bin/bash "$0" "$@"
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN_NAME="XiaoAiCursorConfirm"
DISPLAY_NAME="XiaoAiConfirm"
BUNDLE="${ROOT}/dist/${DISPLAY_NAME}.app"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This script must run on macOS."
  echo "git clone -b cursor/macos-xiaoai-confirm-29b2 https://github.com/AssassinBar/Cloudflare-R2-oss.git"
  echo "cd Cloudflare-R2-oss/xiaoai-cursor-confirm && ./scripts/install-macos.sh"
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "swift not found. Install Xcode or run: xcode-select --install"
  exit 1
fi

echo "Swift: $(swift --version 2>/dev/null | head -n 1)"
echo "Building XiaoAi Cursor Confirm..."
cd "${ROOT}"

swift build -c release --product "${BIN_NAME}" \
  -Xswiftc -parse-as-library \
  -Xswiftc -swift-version -Xswiftc 5 \
  -Xswiftc -strict-concurrency=minimal

BIN_DIR="$(swift build -c release --product "${BIN_NAME}" --show-bin-path)"
BIN_PATH="${BIN_DIR}/${BIN_NAME}"
if [ ! -x "${BIN_PATH}" ]; then
  BIN_PATH="${ROOT}/.build/release/${BIN_NAME}"
fi
if [ ! -x "${BIN_PATH}" ]; then
  echo "Build finished but binary not found: ${BIN_PATH}"
  exit 1
fi

rm -rf "${BUNDLE}"
mkdir -p "${BUNDLE}/Contents/MacOS" "${BUNDLE}/Contents/Resources"
cp "${BIN_PATH}" "${BUNDLE}/Contents/MacOS/${BIN_NAME}"
cp "${ROOT}/Sources/XiaoAiCursorConfirm/Resources/Info.plist" "${BUNDLE}/Contents/Info.plist"
printf 'APPL????' > "${BUNDLE}/Contents/PkgInfo"
chmod +x "${BUNDLE}/Contents/MacOS/${BIN_NAME}" \
  "${ROOT}/cli/xiaoai-cursor.mjs" \
  "${ROOT}/mcp/server.mjs"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "${BUNDLE}" >/dev/null 2>&1 || true
fi
xattr -cr "${BUNDLE}" >/dev/null 2>&1 || true

# Friendly Finder name
FRIENDLY="${ROOT}/dist/XiaoAiConfirm.app"
echo
echo "Built: ${BUNDLE}"
echo "Opening app..."
open "${BUNDLE}"

echo
echo "Next:"
echo "  1. Scan Xiaomi QR in the Test Dock"
echo "  2. Pick a XiaoAi speaker and tap trial playback"
echo "  3. Optional: drag the app to /Applications"
echo "CLI: node ${ROOT}/cli/xiaoai-cursor.mjs health"
