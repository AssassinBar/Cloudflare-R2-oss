# 小爱确认 · Cursor for macOS

Cursor 任务需要你确认时，通过 **小米账号扫码或登录** 授权家里的 **小爱音箱**，用小爱同学原声（含提示音）播报出来。本机同时弹出光球动画，方便你点确认 / 取消。

## 能做什么

- 米家 / 小米账号 App **扫码授权**，或账号密码登录（支持二次验证码）
- 列出账号下的小爱音箱，选择要播报的那一台
- Cursor 确认到达后：音箱先播小爱提示音，再用小爱原声读出确认内容
- 本机 HUD 光球动画：唤醒、说话、听取、成功 / 拒绝
- 音箱不可用时自动回退本机中文语音
- 测试对接：扫码、试听音箱、终端命令 / 写文件 / MCP / Agent 等场景

```
Cursor 需要确认
    → 小爱确认.app（本机光球）
    → 已授权的小爱音箱用小爱同学播报
    ← 你在电脑上确认或取消
```

## 在 Mac 上安装

需要 macOS 13+ 和 Xcode Command Line Tools（或完整 Xcode）。

```bash
cd xiaoai-cursor-confirm
chmod +x scripts/install-macos.sh
./scripts/install-macos.sh
open "dist/小爱确认.app"
```

### 授权小爱音箱

1. 打开应用 → **测试对接** 或 **设置**
2. 点 **扫码登录小米账号**，用米家 / 小米账号 App 扫描
3. 或输入小米账号和密码登录（若需要二次验证，填短信 / 邮箱验证码）
4. 选择要播报的小爱音箱，点 **试听播报**
5. 听到音箱说出「主人，我在…」后即可对接 Cursor

令牌只存在本机钥匙串。默认播报通道是「仅小爱音箱」，失败时回退本机语音。

可在设置里打开麦克风（本机听取确认）和辅助功能（可选，监听 Cursor 对话框）。

## 测试对接

App 主窗口 → **测试对接**：

| 场景 | 作用 |
| --- | --- |
| 扫码 / 登录面板 | 授权小米账号并选择音箱 |
| 小爱音箱播报 | 把确认词打到音箱（含提示音） |
| 终端命令确认 | 模拟 Cursor 申请 `npm test` |
| 写入文件确认 | 模拟覆盖源码 |
| MCP 授权 | 模拟第三方工具授权 |
| Agent 继续执行 | 模拟 Cloud Agent 等待你继续 |
| 危险操作警告 | 高风险命令 |
| 动画状态走查 | 唤醒 → 说话 → 听取 → 成功 → 拒绝 |
| 对接健康检查 | 端口、小米账号、音箱、Cursor 进程 |

不连真实小米账号的协议自测：

```bash
cd xiaoai-cursor-confirm
npm test
node cli/xiaoai-cursor.mjs xiaomi-tts --simulate --text "主人，Cursor 需要你确认"
```

## 让 Cursor 调用小爱音箱

确认请求会先走本机 `127.0.0.1:17880`，App 再调用小米 MiNA（`micoapi`）把文本发到音箱的 `text_to_speech`。

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

小米账号相关：

- `GET /v1/xiaomi/status`
- `POST /v1/xiaomi/qr/start` 开始扫码
- `POST /v1/xiaomi/login` `{"user":"...","password":"...","otp":""}`
- `GET /v1/xiaomi/speakers`
- `POST /v1/xiaomi/tts` `{"text":"主人，Cursor 需要你确认"}`
- `POST /v1/xiaomi/logout`

CLI：

```bash
node cli/xiaoai-cursor.mjs xiaomi-status
node cli/xiaoai-cursor.mjs xiaomi-tts --text "主人，Cursor 需要你确认"
node cli/xiaoai-cursor.mjs confirm --title "允许运行终端命令" --message "npm test"
```

MCP 工具：`xiaoai_confirm`、`xiaoai_mina_tts`、`xiaoai_health`。配置见 `examples/cursor-mcp.json`。

## 目录

```
xiaoai-cursor-confirm/
  Sources/XiaoAiCursorConfirm/   macOS SwiftUI 应用（含小米账号 / MiNA）
  protocol/                      本机协议 + 小米播报测试
  cli/xiaoai-cursor.mjs          命令行
  mcp/server.mjs                 Cursor MCP
  preview/                       光球动画预览
  examples/                      Cursor 配置示例
```

默认端口 `17880`，只绑 loopback。音箱播报走你自己的小米账号云接口，不是第三方 TTS。
