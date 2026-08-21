import Foundation

enum ConfirmKind: String, Codable, CaseIterable, Identifiable {
    case command
    case write
    case mcp
    case agent
    case tool
    case warn
    case test

    var id: String { rawValue }

    var zhTitle: String {
        switch self {
        case .command: return "终端命令"
        case .write: return "写入文件"
        case .mcp: return "MCP 授权"
        case .agent: return "Agent 继续"
        case .tool: return "工具调用"
        case .warn: return "危险操作"
        case .test: return "测试对接"
        }
    }
}

enum ConfirmDecision: String, Codable {
    case approve
    case reject
    case timeout
    case cancelled
}

enum ConfirmVia: String, Codable {
    case voice
    case click
    case keyboard
    case test
    case system
}

enum OrbPhase: String, Codable {
    case idle
    case wake
    case speaking
    case listening
    case success
    case reject
}

struct ConfirmRequest: Codable, Identifiable, Equatable {
    var id: String
    var source: String
    var kind: ConfirmKind
    var title: String
    var message: String
    var detail: String
    var timeoutMs: Int
    var speak: Bool
    var listen: Bool
    var locale: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        source: String = "cursor",
        kind: ConfirmKind = .agent,
        title: String,
        message: String,
        detail: String = "",
        timeoutMs: Int = 60_000,
        speak: Bool = true,
        listen: Bool = true,
        locale: String = "zh-CN",
        createdAt: Date = Date()
    ) {
        self.id = id.isEmpty ? UUID().uuidString : id
        self.source = source.isEmpty ? "cursor" : source
        self.kind = kind
        self.title = title
        self.message = message
        self.detail = detail
        self.timeoutMs = max(3_000, min(timeoutMs, 300_000))
        self.speak = speak
        self.listen = listen
        self.locale = locale
        self.createdAt = createdAt
    }

    var spokenPrompt: String {
        let body = [title, message].filter { !$0.isEmpty }.joined(separator: "。")
        return "主人，Cursor 有一条\(kind.zhTitle)确认。\(body)。请说确认或取消。"
    }

    private enum CodingKeys: String, CodingKey {
        case id, source, kind, title, message, detail, timeoutMs, speak, listen, locale, createdAt, prompt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let decodedId = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        let message = try c.decodeIfPresent(String.self, forKey: .message)
            ?? c.decodeIfPresent(String.self, forKey: .prompt)
            ?? ""
        self.init(
            id: decodedId,
            source: try c.decodeIfPresent(String.self, forKey: .source) ?? "cursor",
            kind: try c.decodeIfPresent(ConfirmKind.self, forKey: .kind) ?? .agent,
            title: try c.decodeIfPresent(String.self, forKey: .title) ?? "Cursor 确认",
            message: message,
            detail: try c.decodeIfPresent(String.self, forKey: .detail) ?? "",
            timeoutMs: try c.decodeIfPresent(Int.self, forKey: .timeoutMs) ?? 60_000,
            speak: try c.decodeIfPresent(Bool.self, forKey: .speak) ?? true,
            listen: try c.decodeIfPresent(Bool.self, forKey: .listen) ?? true,
            locale: try c.decodeIfPresent(String.self, forKey: .locale) ?? "zh-CN",
            createdAt: try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(source, forKey: .source)
        try c.encode(kind, forKey: .kind)
        try c.encode(title, forKey: .title)
        try c.encode(message, forKey: .message)
        try c.encode(detail, forKey: .detail)
        try c.encode(timeoutMs, forKey: .timeoutMs)
        try c.encode(speak, forKey: .speak)
        try c.encode(listen, forKey: .listen)
        try c.encode(locale, forKey: .locale)
        try c.encode(createdAt, forKey: .createdAt)
    }
}

struct ConfirmResponse: Codable {
    var id: String
    var decision: ConfirmDecision
    var via: ConfirmVia
    var transcript: String
    var durationMs: Int
    var spoken: Bool

    var approved: Bool { decision == .approve }

    var spokenResult: String {
        switch decision {
        case .approve: return "好的，已确认。"
        case .reject: return "已取消。"
        case .timeout: return "没有听到回复，我先退下了。"
        case .cancelled: return "这条请求已撤回。"
        }
    }
}

struct HealthPayload: Codable {
    var ok: Bool
    var app: String
    var version: String
    var port: Int
    var phase: OrbPhase
    var pending: Int
    var cursorRunning: Bool
    var microphone: String
    var speech: String
    var voices: [String]
}

struct LogEntry: Identifiable, Equatable {
    let id: UUID
    let at: Date
    let level: String
    let text: String

    init(level: String = "info", text: String) {
        self.id = UUID()
        self.at = Date()
        self.level = level
        self.text = text
    }
}

enum TestScenario: String, CaseIterable, Identifiable {
    case command
    case write
    case mcp
    case agent
    case warn
    case speakOnly
    case listenLoop
    case animationTour
    case health

    var id: String { rawValue }

    var title: String {
        switch self {
        case .command: return "终端命令确认"
        case .write: return "写入文件确认"
        case .mcp: return "MCP 授权"
        case .agent: return "Agent 继续执行"
        case .warn: return "危险操作警告"
        case .speakOnly: return "只播报不听取"
        case .listenLoop: return "语音确认闭环"
        case .animationTour: return "动画状态走查"
        case .health: return "对接健康检查"
        }
    }

    var subtitle: String {
        switch self {
        case .command: return "模拟 Cursor 申请运行一条终端命令"
        case .write: return "模拟 Agent 覆盖写入源文件"
        case .mcp: return "模拟第三方 MCP 需要授权"
        case .agent: return "模拟 Cloud Agent 等待你继续"
        case .warn: return "模拟高风险操作，默认应拒绝"
        case .speakOnly: return "只触发小爱语音提示，不进入听取"
        case .listenLoop: return "播报后进入听取，可用语音确认/取消"
        case .animationTour: return "依次演示唤醒、说话、听取、成功、拒绝"
        case .health: return "检查端口、语音、麦克风与 Cursor 进程"
        }
    }

    func makeRequest() -> ConfirmRequest {
        switch self {
        case .command:
            return ConfirmRequest(
                source: "test",
                kind: .command,
                title: "允许运行终端命令",
                message: "npm test --filter protocol",
                detail: "cwd: ~/Projects/xiaoai-cursor-confirm"
            )
        case .write:
            return ConfirmRequest(
                source: "test",
                kind: .write,
                title: "允许写入文件",
                message: "Sources/XiaoAiCursorConfirm/App.swift",
                detail: "将追加 HUD 动画参数"
            )
        case .mcp:
            return ConfirmRequest(
                source: "test",
                kind: .mcp,
                title: "授权 MCP 工具",
                message: "github.createPullRequest",
                detail: "仓库 AssassinBar/Cloudflare-R2-oss"
            )
        case .agent:
            return ConfirmRequest(
                source: "test",
                kind: .agent,
                title: "继续执行 Cloud Agent",
                message: "Agent 已完成实现，等待你确认提交并推送。",
                detail: "branch: cursor/macos-xiaoai-confirm"
            )
        case .warn:
            return ConfirmRequest(
                source: "test",
                kind: .warn,
                title: "危险操作，请仔细确认",
                message: "rm -rf dist && git push --force",
                detail: "此操作不可撤销"
            )
        case .speakOnly:
            return ConfirmRequest(
                source: "test",
                kind: .test,
                title: "语音提示测试",
                message: "这是一条只播报的小爱提示。",
                timeoutMs: 8_000,
                speak: true,
                listen: false
            )
        case .listenLoop:
            return ConfirmRequest(
                source: "test",
                kind: .test,
                title: "请用语音确认",
                message: "听到提示后请说确认，或者说取消。",
                timeoutMs: 20_000
            )
        case .animationTour, .health:
            return ConfirmRequest(
                source: "test",
                kind: .test,
                title: title,
                message: subtitle,
                timeoutMs: 4_000,
                speak: false,
                listen: false
            )
        }
    }
}
