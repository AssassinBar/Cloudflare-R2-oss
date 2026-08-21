# 小爱确认 · Cursor for macOS

Cursor 需要你点确认时，调用本机 **小爱同学** 风格助手：橙色光球动画、中文语音播报，并听取「确认 / 取消」。给 Cursor 用的 macOS 版本，带完整 **测试对接**。

不是小米官方 SDK。语音使用系统中文 TTS（优先「婷婷」），交互和光球按小爱同学的口吻与动效来做。

## 能做什么

- 浮动 HUD 光球：空闲呼吸、唤醒、说话波形、听取涟漪、成功 / 拒绝
- 语音提示：「主人，Cursor 有一条终端命令确认……请说确认或取消。」
- 口头确认：确认、好的、可以 / 取消、拒绝、不要
- Cursor 对接：本机 HTTP、CLI、MCP、`xiaoai-cursor://` URL
- 可选辅助功能：发现 Cursor 确认框，语音通过后自动点按钮
- 测试对接面板：终端命令、写文件、MCP、Agent、危险操作、动画走查、健康检查

```
Cursor / CLI / MCP  --HTTP 127.0.0.1:17880-->  小爱确认.app
                                              光球动画 + 语音 + 听取
                                         <--  approve | reject | timeout
```

## 在 Mac 上安装

需要 macOS 13+ 和 Xcode Command Line Tools（或完整 Xcode）。

```bash
cd xiaoai-cursor-confirm
chmod +x scripts/install-macos.sh
./scripts/install-macos.sh
open "dist/小爱确认.app"
```

或用 XcodeGen：`brew install xcodegen && xcodegen && xcodebuild -scheme XiaoAiCursorConfirm`.

首次启动会在 `127.0.0.1:17880` 打开对接服务。菜单栏也有「小爱确认」。

系统设置里打开：

1. 麦克风（听取确认）
2. 辅助功能（可选，监听 Cursor 对话框）
3. 下载增强版「婷婷」语音，听感更接近

## 测试对接

App 主窗口 → **测试对接**：

| 场景 | 作用 |
| --- | --- |
| 终端命令确认 | 模拟 Cursor 申请 `npm test` |
| 写入文件确认 | 模拟覆盖源码 |
| MCP 授权 | 模拟第三方工具授权 |
| Agent 继续执行 | 模拟 Cloud Agent 等待你继续 |
| 危险操作警告 | 高风险命令 |
| 只播报不听取 | 只说话，不进入听取 |
| 语音确认闭环 | 播报后等你说确认 / 取消 |
| 动画状态走查 | 唤醒 → 说话 → 听取 → 成功 → 拒绝 |
| 对接健康检查 | 端口、中文语音、Cursor 进程 |

没有 Mac 时，可用浏览器预览动画：

```bash
cd xiaoai-cursor-confirm
npm run preview
# 打开 http://127.0.0.1:4173
```

协议 / CLI / MCP 自测（Linux 和 macOS 都能跑）：

```bash
npm test
# 或 ./scripts/test-dock.sh
node cli/xiaoai-cursor.mjs confirm --simulate --title "允许运行" --message "ls"
```

## 让 Cursor 调用小爱

### 1. HTTP（最直接）

```bash
curl -sS http://127.0.0.1:17880/v1/health

curl -sS -X POST http://127.0.0.1:17880/v1/confirm \
  -H 'Content-Type: application/json' \
  -d '{
    "source": "cursor",
    "kind": "command",
    "title": "允许运行终端命令",
    "message": "npm test",
    "timeoutMs": 20000
  }'
```

成功时返回：

```json
{
  "id": "...",
  "decision": "approve",
  "via": "voice",
  "transcript": "确认",
  "durationMs": 4120,
  "spoken": true
}
```

`kind`：`command` | `write` | `mcp` | `agent` | `tool` | `warn` | `test`  
`decision`：`approve` | `reject` | `timeout` | `cancelled`

其它接口：

- `POST /v1/speak` `{"text":"任务已完成"}`
- `POST /v1/test/scenario` `{"scenario":"command"}`
- `POST /v1/decision` 测试面板远程点确认 / 取消
- `GET /v1/status`

### 2. CLI

退出码：`0` 确认 · `1` 拒绝 · `2` 超时 · `3` 撤回 · `4` 错误

```bash
node cli/xiaoai-cursor.mjs confirm \
  --kind command \
  --title "允许运行终端命令" \
  --message "npm test"

node cli/xiaoai-cursor.mjs speak --text "主人，我在"
node cli/xiaoai-cursor.mjs test --scenario animationTour
```

### 3. MCP

把 `examples/cursor-mcp.json` 合并进 Cursor 的 MCP 配置，工具为：

- `xiaoai_confirm`
- `xiaoai_speak`
- `xiaoai_health`
- `xiaoai_test_scenario`

规则示例见 `examples/cursor-rule.md`：需要用户确认时先调 `xiaoai_confirm`，只有 `approve` 才继续。

无 App 的 CI 可设 `XIAOAI_SIMULATE=1`。

### 4. URL Scheme

```
xiaoai-cursor://confirm?kind=command&title=允许运行终端命令&message=npm%20test
xiaoai-cursor://speak?text=任务已完成
xiaoai-cursor://test?scenario=command
```

## 目录

```
xiaoai-cursor-confirm/
  Sources/XiaoAiCursorConfirm/   macOS SwiftUI 应用
  protocol/                      本机协议 + 测试
  cli/xiaoai-cursor.mjs          命令行
  mcp/server.mjs                 Cursor MCP
  preview/                       光球动画与测试对接网页
  examples/                      Cursor 配置示例
  scripts/install-macos.sh       打包 .app
```

默认端口 `17880`，只绑 loopback。
