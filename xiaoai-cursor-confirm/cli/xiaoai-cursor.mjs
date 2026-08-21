#!/usr/bin/env node
import {
  confirm,
  health,
  minaTTS,
  parseArgs,
  PROTOCOL_VERSION,
  runScenario,
  SCENARIOS,
  simulateConfirm,
  speak,
  xiaomiStatus,
} from "../protocol/index.mjs";
import { qrLoginQuery, simulateMinaAnnounce, speakerConfirmScript } from "../protocol/xiaomi.mjs";

const EXIT = {
  approve: 0,
  reject: 1,
  timeout: 2,
  cancelled: 3,
  error: 4,
};

async function main() {
  const { command, flags } = parseArgs(process.argv);
  const port = flags.port;

  try {
    switch (command) {
      case "help":
      case "--help":
      case "-h":
        printHelp();
        break;
      case "health": {
        const payload = await health(port);
        print(payload, flags);
        if (!payload.ok) process.exitCode = 4;
        break;
      }
      case "confirm": {
        const input = {
          source: flags.source || "cli",
          kind: flags.kind || "agent",
          title: flags.title || "Cursor 确认",
          message: flags.message || flags.prompt || "",
          detail: flags.detail || "",
          timeoutMs: flags.timeout ? Number(flags.timeout) : undefined,
          speak: flags.silent ? false : undefined,
          listen: flags["no-listen"] ? false : undefined,
        };
        const payload = flags.simulate
          ? simulateConfirm(input, flags.transcript || "确认")
          : await confirm(input, port);
        print(payload, flags);
        process.exitCode = EXIT[payload.decision] ?? 4;
        break;
      }
      case "speak": {
        const text = flags.text || flags.message || flags.title || "";
        if (!text) throw new Error("缺少 --text");
        if (flags.simulate) {
          print({ ok: true, spoken: text, simulate: true }, flags);
          break;
        }
        print(await speak(text, port), flags);
        break;
      }
      case "test": {
        const scenario = flags.scenario || "command";
        if (!SCENARIOS[scenario]) {
          throw new Error(`未知场景: ${scenario}，可选 ${Object.keys(SCENARIOS).join(", ")}`);
        }
        if (flags.simulate) {
          const request = SCENARIOS[scenario].request;
          print(request ? simulateConfirm(request, flags.transcript || "确认") : { ok: true, scenario }, flags);
          break;
        }
        print(await runScenario(scenario, port), flags);
        break;
      }
      case "scenarios":
        print(
          Object.values(SCENARIOS).map(({ id, title, subtitle }) => ({ id, title, subtitle })),
          flags
        );
        break;
      case "xiaomi-status": {
        if (flags.simulate) {
          print({ authorized: false, status: "simulate", speakers: [] }, flags);
          break;
        }
        print(await xiaomiStatus(port), flags);
        break;
      }
      case "xiaomi-qr": {
        print(
          {
            loginUrl: "https://account.xiaomi.com/longPolling/loginUrl",
            query: qrLoginQuery(),
            hint: "请在 macOS 小爱确认 App 中扫码。CLI 只打印授权参数。",
          },
          flags
        );
        break;
      }
      case "xiaomi-tts": {
        const text = flags.text || flags.message || speakerConfirmScript("Cursor 确认", "测试播报");
        if (flags.simulate) {
          print(simulateMinaAnnounce({ text, playChime: flags.chime !== "0" }), flags);
          break;
        }
        print(await minaTTS(text, port), flags);
        break;
      }
      case "version":
        print({ app: "xiaoai-cursor", version: PROTOCOL_VERSION }, flags);
        break;
      default:
        throw new Error(`未知命令: ${command}`);
    }
  } catch (error) {
    console.error(error.message || error);
    process.exitCode = EXIT.error;
  }
}

function print(payload, flags) {
  if (flags.quiet) return;
  console.log(JSON.stringify(payload, null, flags.pretty === false ? 0 : 2));
}

function printHelp() {
  console.log(`xiaoai-cursor  小爱同学 Cursor 确认 CLI  v${PROTOCOL_VERSION}

用法:
  xiaoai-cursor health
  xiaoai-cursor confirm --title "允许运行终端命令" --message "npm test"
  xiaoai-cursor speak --text "主人，任务已完成"
  xiaoai-cursor test --scenario command
  xiaoai-cursor xiaomi-qr
  xiaoai-cursor xiaomi-status
  xiaoai-cursor xiaomi-tts --text "主人，Cursor 需要你确认"
  xiaoai-cursor xiaomi-tts --simulate --text "测试播报"

常用参数:
  --port 17880          本机小爱确认服务端口
  --kind command        command|write|mcp|agent|tool|warn|test
  --timeout 20000       等待确认的毫秒
  --simulate            不连接 App，走协议模拟（CI / 测试对接）
  --transcript 确认     模拟语音识别文本

退出码: 0 确认 · 1 拒绝 · 2 超时 · 3 撤回 · 4 错误
`);
}

await main();
