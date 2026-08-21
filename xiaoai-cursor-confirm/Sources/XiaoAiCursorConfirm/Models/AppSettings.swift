import Foundation
import ServiceManagement

@MainActor
final class AppSettings: ObservableObject {
    nonisolated(unsafe) static let shared = AppSettings()

    @Published var port: Int {
        didSet { UserDefaults.standard.set(port, forKey: "port") }
    }

    @Published var catchphrase: String {
        didSet { UserDefaults.standard.set(catchphrase, forKey: "catchphrase") }
    }

    @Published var voiceIdentifier: String {
        didSet { UserDefaults.standard.set(voiceIdentifier, forKey: "voiceIdentifier") }
    }

    @Published var speechRate: Double {
        didSet { UserDefaults.standard.set(speechRate, forKey: "speechRate") }
    }

    @Published var speechPitch: Double {
        didSet { UserDefaults.standard.set(speechPitch, forKey: "speechPitch") }
    }

    @Published var autoListen: Bool {
        didSet { UserDefaults.standard.set(autoListen, forKey: "autoListen") }
    }

    @Published var watchCursorDialogs: Bool {
        didSet { UserDefaults.standard.set(watchCursorDialogs, forKey: "watchCursorDialogs") }
    }

    @Published var autoClickCursor: Bool {
        didSet { UserDefaults.standard.set(autoClickCursor, forKey: "autoClickCursor") }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            Self.setLaunchAtLogin(launchAtLogin)
        }
    }

    @Published var hudScale: Double {
        didSet { UserDefaults.standard.set(hudScale, forKey: "hudScale") }
    }

    @Published var broadcastChannel: String {
        didSet { UserDefaults.standard.set(broadcastChannel, forKey: "broadcastChannel") }
    }

    @Published var selectedSpeakerId: String {
        didSet { UserDefaults.standard.set(selectedSpeakerId, forKey: "selectedSpeakerId") }
    }

    @Published var playXiaoAiChime: Bool {
        didSet { UserDefaults.standard.set(playXiaoAiChime, forKey: "playXiaoAiChime") }
    }

    private init() {
        let defaults = UserDefaults.standard
        port = defaults.object(forKey: "port") as? Int ?? 17880
        catchphrase = defaults.string(forKey: "catchphrase") ?? "小爱同学"
        voiceIdentifier = defaults.string(forKey: "voiceIdentifier") ?? ""
        speechRate = defaults.object(forKey: "speechRate") as? Double ?? 0.47
        speechPitch = defaults.object(forKey: "speechPitch") as? Double ?? 1.08
        autoListen = defaults.object(forKey: "autoListen") as? Bool ?? true
        watchCursorDialogs = defaults.object(forKey: "watchCursorDialogs") as? Bool ?? false
        autoClickCursor = defaults.object(forKey: "autoClickCursor") as? Bool ?? false
        launchAtLogin = defaults.object(forKey: "launchAtLogin") as? Bool ?? false
        hudScale = defaults.object(forKey: "hudScale") as? Double ?? 1.0
        broadcastChannel = defaults.string(forKey: "broadcastChannel") ?? "speaker"
        selectedSpeakerId = defaults.string(forKey: "selectedSpeakerId") ?? ""
        playXiaoAiChime = defaults.object(forKey: "playXiaoAiChime") as? Bool ?? true
    }

    private static func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("launch at login failed: \(error.localizedDescription)")
            }
        }
    }
}
