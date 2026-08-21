import { createHash } from "node:crypto";

export const XIAOMI_ACCOUNT_BASE = "https://account.xiaomi.com";
export const XIAOMI_MINA_BASE = "https://api2.mina.mi.com";
export const XIAOMI_IO_CALLBACK = "https://sts.api.io.mi.com/sts";
export const XIAOMI_SID_HOME = "xiaomiio";
export const XIAOMI_SID_MINA = "micoapi";

export function parseXiaomiJSON(raw) {
  const text = String(raw ?? "").replace(/^&&&START&&&/, "").trim();
  if (!text) return {};
  return JSON.parse(text);
}

export function md5Upper(password) {
  return createHash("md5").update(String(password), "utf8").digest("hex").toUpperCase();
}

export function clientSign(nonce, ssecurity) {
  const nsec = `nonce=${nonce}&${ssecurity}`;
  return createHash("sha1").update(nsec, "utf8").digest("base64");
}

export function qrLoginQuery(deviceId = "TESTDEVICE000001", now = 1700000000000) {
  return {
    _qrsize: "240",
    qs: "%3Fsid%3Dxiaomiio%26_json%3Dtrue",
    callback: XIAOMI_IO_CALLBACK,
    _hasLogo: "false",
    sid: XIAOMI_SID_HOME,
    serviceParam: "",
    _locale: "zh_CN",
    _dc: String(now),
    deviceId,
  };
}

export function ubusTTSBody(deviceId, text, requestId = "app_ios_test") {
  return {
    deviceId,
    method: "text_to_speech",
    path: "mibrain",
    message: JSON.stringify({ text }),
    requestId,
  };
}

export function wakeupBody(deviceId, requestId = "app_ios_test") {
  return {
    deviceId,
    method: "wakeup",
    path: "mibrain",
    message: JSON.stringify({}),
    requestId,
  };
}

export function minaHeaders() {
  return {
    "User-Agent":
      "MiHome/6.0.103 (com.xiaomi.mihome; build:6.0.103.1; iOS 14.4.0) Alamofire/6.0.103 MICO/iOSApp/appStore/6.0.103",
  };
}

export function speakerConfirmScript(title, message) {
  const body = [title, message].filter(Boolean).join("。");
  return `主人，Cursor 有一条确认。${body}。请到电脑上确认或取消。`;
}

export function simulateMinaAnnounce({ deviceId = "speaker-1", name = "客厅小爱", text, playChime = true }) {
  const calls = [];
  if (playChime) calls.push(wakeupBody(deviceId, "app_ios_chime"));
  calls.push(ubusTTSBody(deviceId, text, "app_ios_tts"));
  return {
    ok: true,
    via: "mina-simulate",
    deviceId,
    name,
    playChime,
    text,
    calls,
  };
}
