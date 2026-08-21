#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
node --test protocol/test/protocol.test.mjs
echo "协议 / CLI / MCP 测试对接通过"
