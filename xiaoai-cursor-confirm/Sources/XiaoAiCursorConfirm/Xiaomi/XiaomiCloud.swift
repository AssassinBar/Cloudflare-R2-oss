import AppKit
import Foundation

@MainActor
final class XiaomiCloud: ObservableObject {
    nonisolated(unsafe) static let shared = XiaomiCloud()

    @Published var authorized = false
    @Published var userId = ""
    @Published var speakers: [XiaoAiSpeakerDevice] = []
    @Published var qrImage: NSImage?
    @Published var qrHint = "用米家或小米账号 App 扫描二维码，授权小爱音箱"
    @Published var busy = false
    @Published var status = "未登录小米账号"
    @Published var needsOTP = false

    private var client = XiaomiClient()
    private var token: XiaomiToken?
    private var qrTask: Task<Void, Never>?

    var selectedSpeaker: XiaoAiSpeakerDevice? {
        speakers.first { $0.deviceID == AppSettings.shared.selectedSpeakerId } ?? speakers.first
    }

    private init() {
        if let saved = XiaomiKeychain.load(), saved.isAuthorized {
            token = saved
            authorized = true
            userId = saved.userId
            status = "已登录小米账号 \(saved.userId)"
            Task { await refreshSpeakers() }
        }
    }

    func startQRLogin() {
        qrTask?.cancel()
        qrImage = nil
        busy = true
        qrHint = "正在获取小米账号二维码…"
        qrTask = Task {
            do {
                client = XiaomiClient()
                let session = try await client.startQRLogin()
                qrImage = await loadImage(session.qrURL)
                qrHint = "请用米家 / 小米账号 App 扫码授权小爱音箱"
                status = "等待扫码"
                busy = false
                let token = try await client.waitForQRScan(session)
                try await apply(token)
            } catch is CancellationError {
                busy = false
            } catch {
                busy = false
                status = error.localizedDescription
                qrHint = "扫码失败，请刷新二维码"
                ConfirmCenter.shared.log(error.localizedDescription, level: "error")
            }
        }
    }

    func cancelQR() {
        qrTask?.cancel()
        qrTask = nil
        qrImage = nil
        busy = false
        qrHint = "用米家或小米账号 App 扫描二维码，授权小爱音箱"
    }

    func login(user: String, password: String, otp: String?) async {
        busy = true
        do {
            client = XiaomiClient()
            let token = try await client.login(user: user, password: password, otp: otp)
            try await apply(token)
            needsOTP = false
        } catch {
            let text = error.localizedDescription
            needsOTP = text.contains("二次验证")
            status = text
            ConfirmCenter.shared.log(text, level: "error")
        }
        busy = false
    }

    func logout() {
        cancelQR()
        token = nil
        authorized = false
        userId = ""
        speakers = []
        XiaomiKeychain.clear()
        AppSettings.shared.selectedSpeakerId = ""
        status = "已退出小米账号"
        ConfirmCenter.shared.log("已退出小米账号，小爱音箱授权已清除")
    }

    func refreshSpeakers() async {
        guard let token else { return }
        do {
            speakers = try await client.speakers(token: token)
            if let current = selectedSpeaker {
                AppSettings.shared.selectedSpeakerId = current.deviceID
                status = "已授权 \(current.name)\(current.isOnline ? "（在线）" : "（离线）")"
            } else {
                status = "已登录，但未发现小爱音箱"
            }
            ConfirmCenter.shared.log("小爱音箱 \(speakers.count) 台：\(speakers.map(\.name).joined(separator: "、"))")
        } catch {
            status = error.localizedDescription
            ConfirmCenter.shared.log(error.localizedDescription, level: "error")
        }
    }

    func announce(_ text: String) async throws {
        guard let token else { throw XiaomiError.notAuthorized }
        guard let speaker = selectedSpeaker else { throw XiaomiError.noSpeaker }
        try await client.announce(
            token: token,
            deviceID: speaker.deviceID,
            text: text,
            playChime: AppSettings.shared.playXiaoAiChime
        )
        ConfirmCenter.shared.log("小爱音箱「\(speaker.name)」已播报")
    }

    func testSpeak() async {
        do {
            try await announce("主人，我在。这是 Cursor 小爱确认的音箱测试，之后需要你确认时我会在这里播报。")
            status = "试听已发到 \(selectedSpeaker?.name ?? "小爱音箱")"
        } catch {
            status = error.localizedDescription
            ConfirmCenter.shared.log(error.localizedDescription, level: "error")
        }
    }

    func snapshot() -> XiaomiStatus {
        XiaomiStatus(
            authorized: authorized,
            userId: userId,
            speakerId: selectedSpeaker?.deviceID ?? "",
            speakerName: selectedSpeaker?.name ?? "",
            speakerOnline: selectedSpeaker?.isOnline ?? false,
            speakers: speakers,
            status: status
        )
    }

    private func apply(_ token: XiaomiToken) async throws {
        self.token = token
        authorized = true
        userId = token.userId
        XiaomiKeychain.save(token)
        qrImage = nil
        qrHint = "已授权，Cursor 确认将通过小爱音箱播报"
        ConfirmCenter.shared.log("小米账号 \(token.userId) 已授权小爱音箱")
        await refreshSpeakers()
    }

    private func loadImage(_ url: String) async -> NSImage? {
        guard let real = URL(string: url) else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: real) else { return nil }
        return NSImage(data: data)
    }
}

struct XiaomiStatus: Codable {
    var authorized: Bool
    var userId: String
    var speakerId: String
    var speakerName: String
    var speakerOnline: Bool
    var speakers: [XiaoAiSpeakerDevice]
    var status: String
}
