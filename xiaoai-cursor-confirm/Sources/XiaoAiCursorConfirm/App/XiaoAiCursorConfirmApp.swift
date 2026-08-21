import AppKit
import SwiftUI

@main
struct XiaoAiCursorConfirmApp: App {
    @StateObject private var center = ConfirmCenter.shared
    @StateObject private var settings = AppSettings.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("小爱确认") {
            MainWindow()
                .environmentObject(center)
                .environmentObject(settings)
                .background(WindowConfigurator())
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 980, height: 680)

        MenuBarExtra("小爱确认", systemImage: "waveform.circle.fill") {
            Text(center.serverRunning ? "对接运行中 · \(settings.port)" : "对接未启动")
            Button("测试：终端命令") {
                Task { await center.runScenario(.command) }
            }
            Button("测试：动画走查") {
                Task { await center.runScenario(.animationTour) }
            }
            Button(center.serverRunning ? "停止对接" : "启动对接") {
                if center.serverRunning { center.stopServer() } else { center.startServer() }
            }
            Divider()
            Button("退出") { NSApp.terminate(nil) }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        applyDockIcon()
        ConfirmCenter.shared.startServer()
        CursorAXWatcher.shared.start()
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        true
    }

    @objc func handleURL(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
        guard let link = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: link) else { return }
        URLSchemeHandler.handle(url)
    }

    private func applyDockIcon() {
        let image = XiaoAiDockIcon.make(size: 256)
        NSApp.applicationIconImage = image
    }
}

enum URLSchemeHandler {
    static func handle(_ url: URL) {
        guard url.scheme == "xiaoai-cursor" else { return }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let dict = Dictionary(uniqueKeysWithValues: items.compactMap { item in
            item.value.map { (item.name, $0) }
        })
        switch url.host ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) {
        case "confirm", "v1/confirm":
            let request = ConfirmRequest(
                source: dict["source"] ?? "url",
                kind: ConfirmKind(rawValue: dict["kind"] ?? "") ?? .agent,
                title: dict["title"] ?? "Cursor 确认",
                message: dict["message"] ?? dict["prompt"] ?? "",
                detail: dict["detail"] ?? "",
                timeoutMs: Int(dict["timeoutMs"] ?? "60000") ?? 60_000
            )
            Task { _ = await ConfirmCenter.shared.submit(request) }
        case "speak":
            Task { await XiaoAiSpeaker.shared.speak(dict["text"] ?? dict["message"] ?? "") }
        case "test":
            let scenario = TestScenario(rawValue: dict["scenario"] ?? "command") ?? .command
            Task { await ConfirmCenter.shared.runScenario(scenario) }
        default:
            ConfirmCenter.shared.log("未识别的 URL：\(url.absoluteString)", level: "warn")
        }
    }
}

enum XiaoAiDockIcon {
    static func make(size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            NSColor(red: 0.07, green: 0.08, blue: 0.10, alpha: 1).setFill()
            NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22).fill()
            let inset = size * 0.18
            let orb = rect.insetBy(dx: inset, dy: inset)
            NSColor(red: 1, green: 0.55, blue: 0.12, alpha: 0.35).setFill()
            NSBezierPath(ovalIn: orb.insetBy(dx: -size * 0.06, dy: -size * 0.06)).fill()
            let gradient = NSGradient(colors: [
                NSColor(red: 1, green: 0.95, blue: 0.88, alpha: 1),
                NSColor(red: 1, green: 0.55, blue: 0.10, alpha: 1),
                NSColor(red: 0.92, green: 0.35, blue: 0.05, alpha: 1)
            ])
            gradient?.draw(in: NSBezierPath(ovalIn: orb), relativeCenterPosition: NSPoint(x: -0.25, y: 0.35))
            NSColor.white.withAlphaComponent(0.35).setFill()
            let shine = CGRect(
                x: orb.midX - orb.width * 0.18,
                y: orb.midY + orb.height * 0.08,
                width: orb.width * 0.36,
                height: orb.height * 0.18
            )
            NSBezierPath(ovalIn: shine).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.titleVisibility = .hidden
            view.window?.titlebarAppearsTransparent = true
            view.window?.isMovableByWindowBackground = true
            view.window?.backgroundColor = NSColor(red: 0.07, green: 0.08, blue: 0.10, alpha: 1)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
