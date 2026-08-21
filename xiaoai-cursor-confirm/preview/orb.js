const canvas = document.getElementById("orb");
const ctx = canvas.getContext("2d");
const titleEl = document.getElementById("title");
const messageEl = document.getElementById("message");
const phaseEl = document.getElementById("phaseLabel");
const heardEl = document.getElementById("heard");
const logEl = document.getElementById("log");
const liveToggle = document.getElementById("liveToggle");

const SCENARIOS = [
  ["command", "终端命令确认", "模拟 Cursor 申请运行一条终端命令", { kind: "command", title: "允许运行终端命令", message: "npm test --filter protocol" }],
  ["write", "写入文件确认", "模拟 Agent 覆盖写入源文件", { kind: "write", title: "允许写入文件", message: "Sources/XiaoAiCursorConfirm/App.swift" }],
  ["mcp", "MCP 授权", "模拟第三方 MCP 需要授权", { kind: "mcp", title: "授权 MCP 工具", message: "github.createPullRequest" }],
  ["agent", "Agent 继续执行", "模拟 Cloud Agent 等待你继续", { kind: "agent", title: "继续执行 Cloud Agent", message: "Agent 已完成实现，等待你确认提交并推送。" }],
  ["warn", "危险操作警告", "模拟高风险操作", { kind: "warn", title: "危险操作，请仔细确认", message: "rm -rf dist && git push --force" }],
  ["speakOnly", "只播报不听取", "只触发小爱语音提示", { kind: "test", title: "语音提示测试", message: "这是一条只播报的小爱提示。", listen: false }],
  ["listenLoop", "语音确认闭环", "播报后进入听取", { kind: "test", title: "请用语音确认", message: "听到提示后请说确认，或者说取消。" }],
  ["animationTour", "动画状态走查", "唤醒 → 说话 → 听取 → 成功 → 拒绝", null],
];

let phase = "idle";
let audio = 0.12;
let pending = null;
let settle = null;

const grid = document.getElementById("scenarios");
for (const [id, title, subtitle, request] of SCENARIOS) {
  const button = document.createElement("button");
  button.className = "card";
  button.innerHTML = `<strong>${title}</strong><span>${subtitle}</span>`;
  button.addEventListener("click", () => runScenario(id, request));
  grid.appendChild(button);
}

document.getElementById("customRun").addEventListener("click", () => {
  runScenario("custom", {
    kind: document.getElementById("kind").value,
    title: document.getElementById("customTitle").value,
    message: document.getElementById("customMessage").value,
  });
});
document.getElementById("approveBtn").addEventListener("click", () => decide("approve", "click"));
document.getElementById("rejectBtn").addEventListener("click", () => decide("reject", "click"));

async function runScenario(id, request) {
  log(`测试对接：${id}`);
  if (id === "animationTour") {
    await tour();
    return;
  }
  if (liveToggle.checked) {
    try {
      const payload = await post("/v1/confirm", request);
      log(JSON.stringify(payload, null, 2));
      return;
    } catch (error) {
      log(`本机 App 未连通，改用预览模拟：${error.message}`);
    }
  }
  await present(request);
}

function present(request) {
  pending = request;
  titleEl.textContent = request.title;
  messageEl.textContent = request.message;
  heardEl.textContent = "";
  setPhase("wake");
  speak(`主人，Cursor 有一条确认。${request.title}。${request.message}。请说确认或取消。`);
  setPhase("speaking");
  return new Promise((resolve) => {
    settle = resolve;
    const listen = request.listen !== false;
    setTimeout(() => {
      if (!listen) {
        decide("approve", "system");
        return;
      }
      setPhase("listening");
      listenVoice();
    }, 1600);
  });
}

function decide(decision, via) {
  if (!pending) return;
  const response = {
    id: crypto.randomUUID(),
    decision,
    via,
    transcript: heardEl.textContent.replace("听到：", ""),
    durationMs: 0,
    spoken: true,
  };
  setPhase(decision === "approve" ? "success" : "reject");
  speak(decision === "approve" ? "好的，已确认。" : "已取消。");
  log(JSON.stringify(response, null, 2));
  const done = settle;
  pending = null;
  settle = null;
  setTimeout(() => {
    setPhase("idle");
    titleEl.textContent = "等待 Cursor 调用确认";
    messageEl.textContent = "打开测试对接，或连接本机 17880 端口。";
    done?.(response);
  }, 1200);
}

function listenVoice() {
  const Rec = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!Rec) return;
  const rec = new Rec();
  rec.lang = "zh-CN";
  rec.interimResults = false;
  rec.onresult = (event) => {
    const text = event.results[0][0].transcript;
    heardEl.textContent = `听到：${text}`;
    if (/确认|好的|可以|同意|允许|运行/.test(text)) decide("approve", "voice");
    else if (/取消|拒绝|不行|不要/.test(text)) decide("reject", "voice");
  };
  rec.start();
}

function speak(text) {
  if (!window.speechSynthesis) return;
  window.speechSynthesis.cancel();
  const utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = "zh-CN";
  utterance.rate = 1.02;
  utterance.pitch = 1.08;
  const voice = speechSynthesis.getVoices().find((item) => item.lang.startsWith("zh"));
  if (voice) utterance.voice = voice;
  speechSynthesis.speak(utterance);
}

async function tour() {
  const steps = ["wake", "speaking", "listening", "success", "reject", "idle"];
  titleEl.textContent = "动画状态走查";
  for (const step of steps) {
    setPhase(step);
    messageEl.textContent = step;
    await delay(900);
  }
  titleEl.textContent = "等待 Cursor 调用确认";
  messageEl.textContent = "打开测试对接，或连接本机 17880 端口。";
  log("动画走查完成");
}

async function post(pathname, body) {
  const response = await fetch(`http://127.0.0.1:17880${pathname}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const json = await response.json();
  if (!response.ok) throw new Error(json.error || response.statusText);
  return json;
}

function setPhase(next) {
  phase = next;
  phaseEl.textContent = next;
}

function log(text) {
  logEl.textContent = `${text}\n${logEl.textContent}`.trim();
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function frame(now) {
  const t = now / 1000;
  const w = canvas.width;
  const h = canvas.height;
  const cx = w / 2;
  const cy = h / 2;
  const radius = w * 0.18;
  ctx.clearRect(0, 0, w, h);

  const palette = phase === "success"
    ? ["#7cff9a", "#32d74b"]
    : phase === "reject"
      ? ["#ffb4ae", "#ff453a"]
      : ["#ffe1b5", "#ff8c1a"];

  const target = phase === "speaking" ? 0.45 + Math.abs(Math.sin(t * 8)) * 0.5
    : phase === "listening" ? 0.3
      : 0.12;
  audio += (target - audio) * 0.12;

  const breathe = 1 + 0.04 * Math.sin(t * (phase === "idle" ? 1.2 : 3));
  const g = ctx.createRadialGradient(cx, cy, 10, cx, cy, radius * 2.4);
  g.addColorStop(0, hex(palette[1], 0.35));
  g.addColorStop(1, "rgba(0,0,0,0)");
  ctx.fillStyle = g;
  ctx.beginPath();
  ctx.arc(cx, cy, radius * 2.2 * breathe, 0, Math.PI * 2);
  ctx.fill();

  const rings = phase === "idle" ? 2 : 4;
  for (let i = 0; i < rings; i += 1) {
    const pulse = phase === "listening" ? ((t * 0.55 + i * 0.42) % 1) : 0.35 + 0.2 * Math.sin(t + i);
    const rr = radius * (1.35 + pulse * 1.4 * (0.7 + 0.3 * audio));
    ctx.strokeStyle = hex(palette[1], 0.22 + 0.18 * (1 - pulse));
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(cx, cy, rr, 0, Math.PI * 2);
    ctx.stroke();
  }

  const core = ctx.createRadialGradient(cx - radius * 0.2, cy - radius * 0.25, 8, cx, cy, radius);
  core.addColorStop(0, "#fff8f0");
  core.addColorStop(0.45, palette[0]);
  core.addColorStop(1, palette[1]);
  ctx.fillStyle = core;
  ctx.beginPath();
  ctx.arc(cx, cy, radius * breathe, 0, Math.PI * 2);
  ctx.fill();

  if (phase === "speaking") {
    ctx.fillStyle = "rgba(255,255,255,0.9)";
    for (let i = 0; i < 7; i += 1) {
      const hh = radius * (0.2 + 0.7 * Math.abs(Math.sin(t * 6 + i * 0.7)));
      const bw = 10;
      const x = cx + (i - 3) * 18 - bw / 2;
      roundRect(ctx, x, cy - hh / 2, bw, hh, 5);
      ctx.fill();
    }
  }
  requestAnimationFrame(frame);
}

function hex(color, alpha) {
  const value = color.replace("#", "");
  const n = parseInt(value, 16);
  const r = (n >> 16) & 255;
  const g = (n >> 8) & 255;
  const b = n & 255;
  return `rgba(${r},${g},${b},${alpha})`;
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

requestAnimationFrame(frame);
