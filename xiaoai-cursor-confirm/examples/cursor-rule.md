# Cursor 规则示例：用小爱同学做确认语音提示

把下面内容加到 Cursor User Rules 或项目 `.cursor/rules`：

```
当需要用户确认终端命令、覆盖文件、MCP 授权或继续 Agent 时：
1. 先调用 MCP 工具 xiaoai_confirm（或本机 CLI `node xiaoai-cursor-confirm/cli/xiaoai-cursor.mjs confirm`）
2. 用中文 title + message 描述要确认的动作
3. 只有 decision 为 approve 才继续；reject / timeout 则停止并说明原因
不要在未确认时执行破坏性操作。
```

CLI 例子：

```bash
node xiaoai-cursor-confirm/cli/xiaoai-cursor.mjs confirm \
  --kind command \
  --title "允许运行终端命令" \
  --message "npm test" \
  --timeout 20000
```

URL Scheme：

```
xiaoai-cursor://confirm?kind=command&title=允许运行终端命令&message=npm%20test
```
