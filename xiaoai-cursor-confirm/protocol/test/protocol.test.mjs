import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { createServer } from "node:http";
import { spawn } from "node:child_process";
import { readFileSync } from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  classifyTranscript,
  confirm,
  DECISIONS,
  health,
  KINDS,
  normalizeRequest,
  PHASES,
  PROTOCOL_VERSION,
  SCENARIOS,
  simulateConfirm,
  spokenPrompt,
  validateResponse,
} from "../index.mjs";
import {
  clientSign,
  md5Upper,
  parseXiaomiJSON,
  qrLoginQuery,
  simulateMinaAnnounce,
  speakerConfirmScript,
  ubusTTSBody,
  wakeupBody,
  XIAOMI_SID_HOME,
} from "../xiaomi.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
const cliPath = path.join(root, "cli", "xiaoai-cursor.mjs");
const mcpPath = path.join(root, "mcp", "server.mjs");

test("protocol version is semver", () => {
  assert.match(PROTOCOL_VERSION, /^\d+\.\d+\.\d+$/);
});

test("kinds phases decisions stay in sync with schema", () => {
  const schema = JSON.parse(readFileSync(path.join(path.dirname(fileURLToPath(import.meta.url)), "../schema.json"), "utf8"));
  const defs = schema.$defs;
  assert.deepEqual(defs.kind.enum, KINDS);
  assert.deepEqual(defs.decision.enum, DECISIONS);
  assert.deepEqual(defs.phase.enum, PHASES);
});

test("normalizeRequest fills defaults and aliases prompt", () => {
  const request = normalizeRequest({ title: "允许运行终端命令", prompt: "ls" });
  assert.equal(request.kind, "agent");
  assert.equal(request.message, "ls");
  assert.equal(request.speak, true);
  assert.equal(request.listen, true);
  assert.ok(request.id.length > 8);
  assert.equal(request.timeoutMs, 60_000);
});

test("normalizeRequest clamps timeout and rejects empty title", () => {
  const request = normalizeRequest({ title: "t", message: "m", timeoutMs: 9_999_999, kind: "nope" });
  assert.equal(request.timeoutMs, 300_000);
  assert.equal(request.kind, "agent");
  assert.throws(() => normalizeRequest({ title: "   ", message: "x" }));
});

test("spoken prompt uses XiaoAi catchphrase style", () => {
  const text = spokenPrompt(
    normalizeRequest({ kind: "command", title: "允许运行终端命令", message: "npm test" })
  );
  assert.match(text, /^主人，Cursor 有一条终端命令确认/);
  assert.match(text, /请说确认或取消/);
});

test("voice classifier understands 确认 and 取消", () => {
  assert.equal(classifyTranscript("好的，确认").decision, "approve");
  assert.equal(classifyTranscript("小爱取消").decision, "reject");
  assert.equal(classifyTranscript("今天天气"), null);
});

test("all test-dock scenarios are well formed", () => {
  for (const scenario of Object.values(SCENARIOS)) {
    assert.ok(scenario.id);
    assert.ok(scenario.title);
    assert.ok(scenario.subtitle);
    if (scenario.request) {
      const request = normalizeRequest(scenario.request);
      assert.ok(KINDS.includes(request.kind));
      assert.ok(spokenPrompt(request).includes("主人"));
    }
  }
});

test("simulateConfirm returns a valid protocol response", () => {
  const approved = simulateConfirm({ title: "t", message: "m" }, "确认");
  validateResponse(approved);
  assert.equal(approved.decision, "approve");
  assert.equal(approved.via, "test");
  const rejected = simulateConfirm({ title: "t", message: "m" }, "拒绝");
  assert.equal(rejected.decision, "reject");
});

test("CLI simulate confirm exits 0 on 确认 and 1 on 取消", async () => {
  const ok = await runCli(["confirm", "--simulate", "--title", "测试", "--message", "demo", "--transcript", "确认"]);
  assert.equal(ok.code, 0);
  assert.equal(JSON.parse(ok.stdout).decision, "approve");

  const no = await runCli(["confirm", "--simulate", "--title", "测试", "--message", "demo", "--transcript", "取消"]);
  assert.equal(no.code, 1);
  assert.equal(JSON.parse(no.stdout).decision, "reject");
});

test("CLI lists scenarios used by the test dock", async () => {
  const result = await runCli(["scenarios"]);
  assert.equal(result.code, 0);
  const list = JSON.parse(result.stdout);
  assert.equal(list.length, Object.keys(SCENARIOS).length);
  assert.ok(list.some((item) => item.id === "animationTour"));
});

test("HTTP test dock: health + confirm + decision payload", async () => {
  const server = await listenMock();
  try {
    const healthy = await health(server.port);
    assert.equal(healthy.ok, true);
    assert.equal(healthy.app, "XiaoAiCursorConfirm");

    const response = await confirm(
      { source: "cursor", kind: "command", title: "允许运行终端命令", message: "npm test" },
      server.port
    );
    assert.equal(response.decision, "approve");
    assert.equal(response.via, "test");
    assert.equal(server.lastRequest.kind, "command");
    assert.equal(server.lastRequest.title, "允许运行终端命令");
  } finally {
    await server.close();
  }
});

test("MCP stdio initialize, list tools, and simulate confirm", async () => {
  const child = spawn(process.execPath, [mcpPath], {
    env: { ...process.env, XIAOAI_SIMULATE: "1" },
    stdio: ["pipe", "pipe", "pipe"],
  });
  const replies = [];
  child.stdout.setEncoding("utf8");
  child.stdout.on("data", (chunk) => {
    for (const line of chunk.split("\n").filter(Boolean)) replies.push(JSON.parse(line));
  });

  const send = (message) => child.stdin.write(`${JSON.stringify(message)}\n`);
  send({ jsonrpc: "2.0", id: 1, method: "initialize", params: { protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "test" } } });
  send({ jsonrpc: "2.0", id: 2, method: "tools/list" });
  send({
    jsonrpc: "2.0",
    id: 3,
    method: "tools/call",
    params: { name: "xiaoai_confirm", arguments: { title: "允许运行", message: "ls", kind: "command" } },
  });

  await waitUntil(() => replies.length >= 3, 3000);
  child.kill();

  assert.equal(replies[0].result.serverInfo.name, "xiaoai-cursor-confirm");
  const names = replies[1].result.tools.map((tool) => tool.name);
  assert.ok(names.includes("xiaoai_confirm"));
  assert.ok(names.includes("xiaoai_mina_tts"));
  assert.ok(names.includes("xiaoai_test_scenario"));
  const called = JSON.parse(replies[2].result.content[0].text);
  assert.equal(called.decision, "approve");
});

test("Xiaomi JSON prefix is stripped", () => {
  const parsed = parseXiaomiJSON('&&&START&&&{"code":0,"result":"ok"}');
  assert.equal(parsed.code, 0);
  assert.equal(parsed.result, "ok");
});

test("Xiaomi password hash is MD5 uppercase", () => {
  assert.equal(md5Upper("123456"), "E10ADC3949BA59ABBE56E057F20F883E");
});

test("Xiaomi STS clientSign matches SHA1 base64", () => {
  assert.equal(clientSign("123", "sec"), createHash("sha1").update("nonce=123&sec").digest("base64"));
});

test("QR login targets Mi Home sid for 扫码授权", () => {
  const query = qrLoginQuery("DEV123");
  assert.equal(query.sid, XIAOMI_SID_HOME);
  assert.equal(query.callback, "https://sts.api.io.mi.com/sts");
  assert.equal(query._locale, "zh_CN");
});

test("MiNA TTS ubus payload uses XiaoAi mibrain text_to_speech", () => {
  const body = ubusTTSBody("did-1", "主人，Cursor 需要确认");
  assert.equal(body.method, "text_to_speech");
  assert.equal(body.path, "mibrain");
  assert.equal(JSON.parse(body.message).text, "主人，Cursor 需要确认");
  assert.equal(wakeupBody("did-1").method, "wakeup");
});

test("speaker confirm script is XiaoAi catchphrase", () => {
  const text = speakerConfirmScript("允许运行终端命令", "npm test");
  assert.match(text, /^主人，Cursor 有一条确认/);
  assert.match(text, /请到电脑上确认或取消/);
});

test("simulateMinaAnnounce plays chime then TTS", () => {
  const result = simulateMinaAnnounce({
    deviceId: "lx06",
    name: "客厅小爱",
    text: "主人，我在",
    playChime: true,
  });
  assert.equal(result.ok, true);
  assert.equal(result.via, "mina-simulate");
  assert.equal(result.calls[0].method, "wakeup");
  assert.equal(result.calls[1].method, "text_to_speech");
});

test("CLI xiaomi-tts --simulate returns mina payload", async () => {
  const result = await runCli(["xiaomi-tts", "--simulate", "--text", "主人，Cursor 需要你确认"]);
  assert.equal(result.code, 0);
  const payload = JSON.parse(result.stdout);
  assert.equal(payload.ok, true);
  assert.equal(payload.calls[1].method, "text_to_speech");
});

test("speaker scenario exists in test dock catalog", () => {
  assert.equal(SCENARIOS.speaker.title, "小爱音箱播报");
  assert.ok(SCENARIOS.speaker.request.message.includes("Cursor"));
});

function runCli(args) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, [cliPath, ...args], { cwd: root });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => {
      stdout += chunk;
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });
    child.on("error", reject);
    child.on("close", (code) => resolve({ code, stdout, stderr }));
  });
}

function listenMock() {
  return new Promise((resolve) => {
    const state = { lastRequest: null, port: 0 };
    const server = createServer((req, res) => {
      const chunks = [];
      req.on("data", (chunk) => chunks.push(chunk));
      req.on("end", () => {
        const raw = Buffer.concat(chunks).toString("utf8");
        const body = raw ? JSON.parse(raw) : {};
        res.setHeader("Content-Type", "application/json");
        if (req.url === "/v1/health") {
          res.end(JSON.stringify({
            ok: true,
            app: "XiaoAiCursorConfirm",
            version: PROTOCOL_VERSION,
            port: state.port,
            phase: "idle",
            pending: 0,
            cursorRunning: false,
            microphone: "idle",
            speech: "idle",
            voices: ["Tingting"],
          }));
          return;
        }
        if (req.url === "/v1/confirm") {
          state.lastRequest = body;
          res.end(JSON.stringify({
            id: body.id || "mock",
            decision: "approve",
            via: "test",
            transcript: "确认",
            durationMs: 42,
            spoken: true,
          }));
          return;
        }
        res.statusCode = 404;
        res.end(JSON.stringify({ error: "not found" }));
      });
    });
    server.listen(0, "127.0.0.1", () => {
      state.port = server.address().port;
      state.close = () => new Promise((done) => server.close(done));
      resolve(state);
    });
  });
}

async function waitUntil(predicate, timeoutMs) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if (predicate()) return;
    await new Promise((resolve) => setTimeout(resolve, 25));
  }
  throw new Error("timed out waiting for MCP replies");
}
