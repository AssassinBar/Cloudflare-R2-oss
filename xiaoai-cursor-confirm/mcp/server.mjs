#!/usr/bin/env node
import { stdin as input, stdout as output } from "node:process";
import readline from "node:readline";
import {
  confirm,
  health,
  minaTTS,
  PROTOCOL_VERSION,
  runScenario,
  simulateConfirm,
  speak,
} from "../protocol/index.mjs";
import { simulateMinaAnnounce } from "../protocol/xiaomi.mjs";

const simulate = process.env.XIAOAI_SIMULATE === "1";
const tools = [
  {
    name: "xiaoai_confirm",
    description:
      "调用已授权的小爱音箱播报 Cursor 确认（小爱原声）。同时弹出 macOS 光球，用户确认/取消后返回结果。",
    inputSchema: {
      type: "object",
      required: ["title", "message"],
      properties: {
        title: { type: "string" },
        message: { type: "string" },
        kind: { type: "string", enum: ["command", "write", "mcp", "agent", "tool", "warn", "test"] },
        detail: { type: "string" },
        timeoutMs: { type: "integer" },
        speak: { type: "boolean" },
        listen: { type: "boolean" },
      },
    },
  },
  {
    name: "xiaoai_speak",
    description: "让小爱同学朗读一条状态提示，不进入确认。",
    inputSchema: {
      type: "object",
      required: ["text"],
      properties: { text: { type: "string" } },
    },
  },
  {
    name: "xiaoai_health",
    description: "检查小爱确认助手、小米账号授权和小爱音箱是否可用。",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "xiaoai_test_scenario",
    description: "运行内置测试对接场景，例如 command、speaker、animationTour。",
    inputSchema: {
      type: "object",
      required: ["scenario"],
      properties: {
        scenario: { type: "string" },
        transcript: { type: "string" },
      },
    },
  },
  {
    name: "xiaoai_mina_tts",
    description: "把一段话通过已授权的小爱音箱用小爱同学原声播报出来，不进入确认。",
    inputSchema: {
      type: "object",
      required: ["text"],
      properties: { text: { type: "string" } },
    },
  },
];

const rl = readline.createInterface({ input, crlfDelay: Infinity });

rl.on("line", async (line) => {
  const trimmed = line.trim();
  if (!trimmed) return;
  let message;
  try {
    message = JSON.parse(trimmed);
  } catch {
    return;
  }
  try {
    const result = await handle(message);
    if (result) write(result);
  } catch (error) {
    write({
      jsonrpc: "2.0",
      id: message.id ?? null,
      error: { code: -32603, message: error.message || String(error) },
    });
  }
});

async function handle(message) {
  const { id, method, params } = message;
  if (method === "initialize") {
    return {
      jsonrpc: "2.0",
      id,
      result: {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        serverInfo: { name: "xiaoai-cursor-confirm", version: PROTOCOL_VERSION },
      },
    };
  }
  if (method === "notifications/initialized" || method === "initialized") {
    return null;
  }
  if (method === "tools/list") {
    return { jsonrpc: "2.0", id, result: { tools } };
  }
  if (method === "ping") {
    return { jsonrpc: "2.0", id, result: {} };
  }
  if (method === "tools/call") {
    const name = params?.name;
    const args = params?.arguments || {};
    const payload = await callTool(name, args);
    return {
      jsonrpc: "2.0",
      id,
      result: {
        content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
        isError: payload?.ok === false,
        structuredContent: payload,
      },
    };
  }
  return {
    jsonrpc: "2.0",
    id,
    error: { code: -32601, message: `Unknown method: ${method}` },
  };
}

async function callTool(name, args) {
  switch (name) {
    case "xiaoai_confirm":
      return simulate ? simulateConfirm(args, args.transcript || "确认") : confirm(args);
    case "xiaoai_speak":
      return simulate ? { ok: true, spoken: args.text, simulate: true } : speak(args.text);
    case "xiaoai_health":
      return simulate
        ? { ok: true, app: "XiaoAiCursorConfirm", version: PROTOCOL_VERSION, port: 17880, simulate: true }
        : health();
    case "xiaoai_test_scenario":
      return simulate
        ? simulateConfirm({ title: args.scenario, message: "test" }, args.transcript || "确认")
        : runScenario(args.scenario);
    case "xiaoai_mina_tts":
      return simulate ? simulateMinaAnnounce({ text: args.text || "主人，我在" }) : minaTTS(args.text);
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

function write(message) {
  output.write(`${JSON.stringify(message)}\n`);
}
