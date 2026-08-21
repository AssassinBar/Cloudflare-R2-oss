export const DEFAULT_PORT = 17880;
export const DEFAULT_HOST = "127.0.0.1";
export const APP_NAME = "XiaoAiCursorConfirm";
export const PROTOCOL_VERSION = "1.1.0";

export const KINDS = ["command", "write", "mcp", "agent", "tool", "warn", "test"];
export const DECISIONS = ["approve", "reject", "timeout", "cancelled"];
export const VIAS = ["voice", "click", "keyboard", "test", "system"];
export const PHASES = ["idle", "wake", "speaking", "listening", "success", "reject"];

export const APPROVE_WORDS = ["确认", "好的", "可以", "同意", "行", "批准", "运行", "允许", "好", "是", "小爱确认"];
export const REJECT_WORDS = ["取消", "拒绝", "不行", "不要", "算了", "否", "停", "小爱取消"];

export const SCENARIOS = {
  command: {
    id: "command",
    title: "终端命令确认",
    subtitle: "模拟 Cursor 申请运行一条终端命令",
    request: {
      source: "test",
      kind: "command",
      title: "允许运行终端命令",
      message: "npm test --filter protocol",
      detail: "cwd: ~/Projects/xiaoai-cursor-confirm",
    },
  },
  write: {
    id: "write",
    title: "写入文件确认",
    subtitle: "模拟 Agent 覆盖写入源文件",
    request: {
      source: "test",
      kind: "write",
      title: "允许写入文件",
      message: "Sources/XiaoAiCursorConfirm/App.swift",
    },
  },
  mcp: {
    id: "mcp",
    title: "MCP 授权",
    subtitle: "模拟第三方 MCP 需要授权",
    request: {
      source: "test",
      kind: "mcp",
      title: "授权 MCP 工具",
      message: "github.createPullRequest",
    },
  },
  agent: {
    id: "agent",
    title: "Agent 继续执行",
    subtitle: "模拟 Cloud Agent 等待你继续",
    request: {
      source: "test",
      kind: "agent",
      title: "继续执行 Cloud Agent",
      message: "Agent 已完成实现，等待你确认提交并推送。",
    },
  },
  warn: {
    id: "warn",
    title: "危险操作警告",
    subtitle: "模拟高风险操作，默认应拒绝",
    request: {
      source: "test",
      kind: "warn",
      title: "危险操作，请仔细确认",
      message: "rm -rf dist && git push --force",
    },
  },
  speakOnly: {
    id: "speakOnly",
    title: "只播报不听取",
    subtitle: "只触发小爱语音提示，不进入听取",
    request: {
      source: "test",
      kind: "test",
      title: "语音提示测试",
      message: "这是一条只播报的小爱提示。",
      listen: false,
      timeoutMs: 8000,
    },
  },
  listenLoop: {
    id: "listenLoop",
    title: "语音确认闭环",
    subtitle: "播报后进入听取，可用语音确认/取消",
    request: {
      source: "test",
      kind: "test",
      title: "请用语音确认",
      message: "听到提示后请说确认，或者说取消。",
      timeoutMs: 20000,
    },
  },
  animationTour: {
    id: "animationTour",
    title: "动画状态走查",
    subtitle: "依次演示唤醒、说话、听取、成功、拒绝",
    request: {
      source: "test",
      kind: "test",
      title: "动画状态走查",
      message: "依次演示唤醒、说话、听取、成功、拒绝",
      speak: false,
      listen: false,
    },
  },
  speaker: {
    id: "speaker",
    title: "小爱音箱播报",
    subtitle: "授权后把确认词打到小爱音箱（含提示音）",
    request: {
      source: "test",
      kind: "test",
      title: "小爱音箱播报测试",
      message: "Cursor 有一条确认请求，请在电脑上点确认或取消。",
      timeoutMs: 20000,
    },
  },
  health: {
    id: "health",
    title: "对接健康检查",
    subtitle: "检查端口、语音、麦克风、小米账号与 Cursor 进程",
    request: null,
  },
};

export function normalizeRequest(input = {}) {
  const message = input.message ?? input.prompt ?? "";
  const title = input.title || "Cursor 确认";
  if (!title.trim()) {
    throw new Error("title is required");
  }
  const timeoutMs = clamp(Number(input.timeoutMs ?? 60_000), 3_000, 300_000);
  const kind = KINDS.includes(input.kind) ? input.kind : "agent";
  return {
    id: input.id || crypto.randomUUID(),
    source: input.source || "cursor",
    kind,
    title,
    message,
    detail: input.detail || "",
    timeoutMs,
    speak: input.speak !== false,
    listen: input.listen !== false,
    locale: input.locale || "zh-CN",
  };
}

export function spokenPrompt(request) {
  const body = [request.title, request.message].filter(Boolean).join("。");
  const kindTitle = {
    command: "终端命令",
    write: "写入文件",
    mcp: "MCP 授权",
    agent: "Agent 继续",
    tool: "工具调用",
    warn: "危险操作",
    test: "测试对接",
  }[request.kind] || "确认";
  return `主人，Cursor 有一条${kindTitle}确认。${body}。请说确认或取消。`;
}

export function classifyTranscript(raw) {
  const text = String(raw || "").trim();
  if (!text) return null;
  if (APPROVE_WORDS.some((word) => text.includes(word))) {
    return { decision: "approve", transcript: text };
  }
  if (REJECT_WORDS.some((word) => text.includes(word))) {
    return { decision: "reject", transcript: text };
  }
  return null;
}

export function validateResponse(payload) {
  if (!payload || typeof payload !== "object") throw new Error("response must be an object");
  if (!payload.id) throw new Error("response.id is required");
  if (!DECISIONS.includes(payload.decision)) throw new Error(`invalid decision: ${payload.decision}`);
  if (!VIAS.includes(payload.via)) throw new Error(`invalid via: ${payload.via}`);
  return payload;
}

export function baseUrl(port = process.env.XIAOAI_PORT || DEFAULT_PORT, host = DEFAULT_HOST) {
  return `http://${host}:${port}`;
}

export async function requestJson(url, { method = "GET", body, timeoutMs = 65_000 } = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, {
      method,
      headers: body ? { "Content-Type": "application/json" } : undefined,
      body: body ? JSON.stringify(body) : undefined,
      signal: controller.signal,
    });
    const text = await response.text();
    let json = null;
    try {
      json = text ? JSON.parse(text) : null;
    } catch {
      json = { raw: text };
    }
    if (!response.ok) {
      const error = new Error(json?.error || `HTTP ${response.status}`);
      error.status = response.status;
      error.payload = json;
      throw error;
    }
    return json;
  } finally {
    clearTimeout(timer);
  }
}

export async function health(port) {
  return requestJson(`${baseUrl(port)}/v1/health`, { timeoutMs: 3000 });
}

export async function confirm(input, port) {
  const request = normalizeRequest(input);
  const timeoutMs = request.timeoutMs + 5_000;
  const response = await requestJson(`${baseUrl(port)}/v1/confirm`, {
    method: "POST",
    body: request,
    timeoutMs,
  });
  return validateResponse(response);
}

export async function speak(text, port) {
  return requestJson(`${baseUrl(port)}/v1/speak`, {
    method: "POST",
    body: { text },
    timeoutMs: 30_000,
  });
}

export async function minaTTS(text, port) {
  return requestJson(`${baseUrl(port)}/v1/xiaomi/tts`, {
    method: "POST",
    body: { text },
    timeoutMs: 30_000,
  });
}

export async function xiaomiStatus(port) {
  return requestJson(`${baseUrl(port)}/v1/xiaomi/status`, { timeoutMs: 5000 });
}

export async function runScenario(scenario, port) {
  return requestJson(`${baseUrl(port)}/v1/test/scenario`, {
    method: "POST",
    body: { scenario },
    timeoutMs: 80_000,
  });
}

export function simulateConfirm(input, transcript = "确认") {
  const request = normalizeRequest(input);
  const classified = classifyTranscript(transcript) || { decision: "timeout", transcript: "" };
  return {
    id: request.id,
    decision: classified.decision,
    via: classified.transcript ? "test" : "system",
    transcript: classified.transcript || "",
    durationMs: 12,
    spoken: request.speak,
  };
}

function clamp(value, min, max) {
  if (!Number.isFinite(value)) return min;
  return Math.min(max, Math.max(min, value));
}

export function parseArgs(argv) {
  const args = argv.slice(2);
  const command = args.find((item) => !item.startsWith("-")) || "help";
  const flags = {};
  for (let i = 0; i < args.length; i += 1) {
    const item = args[i];
    if (!item.startsWith("--")) continue;
    const key = item.slice(2);
    const next = args[i + 1];
    if (!next || next.startsWith("--")) {
      flags[key] = true;
    } else {
      flags[key] = next;
      i += 1;
    }
  }
  return { command, flags };
}
