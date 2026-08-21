import AppKit
import Foundation
import SwiftUI

@MainActor
final class ConfirmCenter: ObservableObject {
    nonisolated(unsafe) static let shared = ConfirmCenter()

    @Published var current: ConfirmRequest?
    @Published var phase: OrbPhase = .idle
    @Published var audioLevel: Double = 0.12
    @Published var transcript: String = ""
    @Published var logs: [LogEntry] = []
    @Published var serverRunning = false
    @Published var lastResponse: ConfirmResponse?
    @Published var pendingCount = 0

    private var sessionContinuation: CheckedContinuation<ConfirmResponse, Never>?
    private var startedAt = Date()
    private var settled = false
    private var pulseTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var listenTask: Task<Void, Never>?
    private var finishTask: Task<Void, Never>?
    private let server = ConfirmHTTPServer()
    private var queue: [(ConfirmRequest, CheckedContinuation<ConfirmResponse, Never>)] = []
    private var pumping = false

    private init() {
        server.center = self
    }

    func startServer() {
        do {
            try server.start(port: UInt16(AppSettings.shared.port))
            serverRunning = true
            log("本地对接已启动 http://127.0.0.1:\(AppSettings.shared.port)")
        } catch {
            serverRunning = false
            log("对接启动失败：\(error.localizedDescription)", level: "error")
        }
    }

    func stopServer() {
        server.stop()
        serverRunning = false
        log("本地对接已停止")
    }

    func submit(_ request: ConfirmRequest) async -> ConfirmResponse {
        await withCheckedContinuation { continuation in
            queue.append((request, continuation))
            pendingCount = queue.count + (current == nil ? 0 : 1)
            log("收到 \(request.kind.zhTitle)：\(request.title)")
            if !pumping {
                pumping = true
                Task { await self.pump() }
            }
        }
    }

    func decide(_ decision: ConfirmDecision, via: ConfirmVia, transcript: String) {
        guard !settled, let request = current else { return }
        settled = true
        timeoutTask?.cancel()
        listenTask?.cancel()
        XiaoAiListener.shared.stop()
        XiaoAiSpeaker.shared.stop()
        self.transcript = transcript
        let duration = Int(Date().timeIntervalSince(startedAt) * 1000)
        let response = ConfirmResponse(
            id: request.id,
            decision: decision,
            via: via,
            transcript: transcript,
            durationMs: duration,
            spoken: request.speak
        )
        lastResponse = response
        phase = decision == .approve ? .success : (decision == .timeout ? .idle : .reject)
        log("结果 \(decision.rawValue) via \(via.rawValue) — \(request.title)")

        finishTask?.cancel()
        finishTask = Task { [weak self] in
            guard let self else { return }
            if request.speak {
                await announce(response.spokenResult)
            } else {
                try? await Task.sleep(nanoseconds: 450_000_000)
            }
            try? await Task.sleep(nanoseconds: 280_000_000)
            ConfirmHUDController.shared.hide()
            self.current = nil
            self.phase = .idle
            self.stopPulse()
            if AppSettings.shared.autoClickCursor, request.source.contains("cursor") {
                CursorAXWatcher.shared.click(matching: decision)
            }
            self.sessionContinuation?.resume(returning: response)
            self.sessionContinuation = nil
        }
    }

    func runScenario(_ scenario: TestScenario) async {
        log("测试对接：\(scenario.title)")
        switch scenario {
        case .animationTour:
            await playAnimationTour()
        case .health:
            log(healthSummary())
        default:
            _ = await submit(scenario.makeRequest())
        }
    }

    func playAnimationTour() async {
        ConfirmHUDController.shared.show(center: self)
        current = TestScenario.animationTour.makeRequest()
        startPulse()
        let sequence: [(OrbPhase, UInt64)] = [
            (.wake, 700_000_000),
            (.speaking, 1_200_000_000),
            (.listening, 1_200_000_000),
            (.success, 800_000_000),
            (.reject, 800_000_000),
            (.idle, 400_000_000)
        ]
        for (next, wait) in sequence {
            phase = next
            audioLevel = next == .speaking ? 0.8 : 0.2
            try? await Task.sleep(nanoseconds: wait)
        }
        current = nil
        stopPulse()
        ConfirmHUDController.shared.hide()
        log("动画走查完成")
    }

    func health() -> HealthPayload {
        let voices = XiaoAiSpeaker.shared.availableVoices().map(\.name)
        let xiaomi = XiaomiCloud.shared.snapshot()
        return HealthPayload(
            ok: serverRunning,
            app: "XiaoAiCursorConfirm",
            version: "1.1.0",
            port: AppSettings.shared.port,
            phase: phase,
            pending: pendingCount,
            cursorRunning: CursorAXWatcher.shared.isCursorRunning,
            microphone: XiaoAiListener.shared.isListening ? "listening" : "idle",
            speech: XiaoAiSpeaker.shared.isSpeaking ? "speaking" : "idle",
            voices: voices,
            xiaomiAuthorized: xiaomi.authorized,
            speakerName: xiaomi.speakerName,
            speakerOnline: xiaomi.speakerOnline,
            broadcastChannel: AppSettings.shared.broadcastChannel
        )
    }

    func healthSummary() -> String {
        let h = health()
        let speaker = h.xiaomiAuthorized
            ? "小爱音箱 \(h.speakerName.isEmpty ? "未选择" : h.speakerName)\(h.speakerOnline ? " 在线" : " 离线")"
            : "小米账号未授权"
        return "对接 \(h.ok ? "正常" : "未启动") · \(speaker) · Cursor \(h.cursorRunning ? "在运行" : "未发现")"
    }

    func announce(_ text: String) async {
        let channel = AppSettings.shared.broadcastChannel
        var speakerOK = false
        if channel != "local", XiaomiCloud.shared.authorized {
            do {
                try await XiaomiCloud.shared.announce(text)
                speakerOK = true
            } catch {
                log("小爱音箱播报失败：\(error.localizedDescription)", level: "error")
            }
        }
        let shouldSpeakLocally = channel == "local" || channel == "both" || !speakerOK
        if shouldSpeakLocally {
            if !speakerOK, channel == "speaker" {
                log("音箱不可用，回退到本机语音")
            }
            await XiaoAiSpeaker.shared.speak(text)
        } else {
            let seconds = min(8.0, max(2.2, Double(text.count) * 0.16))
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    }

    func log(_ text: String, level: String = "info") {
        logs.insert(LogEntry(level: level, text: text), at: 0)
        if logs.count > 200 { logs.removeLast(logs.count - 200) }
    }

    private func pump() async {
        while !queue.isEmpty {
            let (request, continuation) = queue.removeFirst()
            pendingCount = queue.count + 1
            let response = await runSession(request)
            continuation.resume(returning: response)
        }
        pendingCount = 0
        pumping = false
    }

    private func runSession(_ request: ConfirmRequest) async -> ConfirmResponse {
        await withCheckedContinuation { continuation in
            sessionContinuation = continuation
            settled = false
            current = request
            transcript = ""
            startedAt = Date()
            phase = .wake
            ConfirmHUDController.shared.show(center: self)
            NSApp.activate(ignoringOtherApps: true)
            startPulse()
            Task { await self.drive(request) }
        }
    }

    private func drive(_ request: ConfirmRequest) async {
        if request.speak {
            phase = .speaking
            await announce(request.spokenPrompt)
            if settled { return }
        }

        if request.listen && AppSettings.shared.autoListen {
            phase = .listening
            listenTask = Task { [weak self] in
                guard let self else { return }
                if let (decision, text) = await XiaoAiListener.shared.waitForDecision(timeoutMs: request.timeoutMs) {
                    await MainActor.run {
                        self.decide(decision, via: .voice, transcript: text)
                    }
                }
            }
        } else if !request.listen {
            decide(.approve, via: .system, transcript: "")
            return
        } else {
            phase = .listening
        }

        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            let ns = UInt64(request.timeoutMs) * 1_000_000
            try? await Task.sleep(nanoseconds: ns)
            await MainActor.run {
                self?.decide(.timeout, via: .system, transcript: "")
            }
        }
    }

    private func startPulse() {
        pulseTask?.cancel()
        pulseTask = Task {
            while !Task.isCancelled {
                let target: Double
                switch phase {
                case .speaking: target = 0.45 + Double.random(in: 0...0.55)
                case .listening: target = 0.25 + Double.random(in: 0...0.25)
                case .wake: target = 0.7
                default: target = 0.12
                }
                audioLevel += (target - audioLevel) * 0.25
                try? await Task.sleep(nanoseconds: 80_000_000)
            }
        }
    }

    private func stopPulse() {
        pulseTask?.cancel()
        audioLevel = 0.12
    }
}
