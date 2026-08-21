import AppKit
import ApplicationServices

@MainActor
final class CursorAXWatcher: ObservableObject {
    static let shared = CursorAXWatcher()

    @Published private(set) var isCursorRunning = false
    @Published private(set) var lastDialog = ""
    @Published var trusted = AXIsProcessTrusted()

    private var timer: Timer?
    private let cursorBundleHints = [
        "com.todesktop.230313mzl4w4u92",
        "com.anysphere.cursor",
        "Cursor"
    ]

    func start() {
        stop()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func requestTrust() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        trusted = AXIsProcessTrustedWithOptions(options)
    }

    var cursorApp: NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { app in
            let bundle = app.bundleIdentifier ?? ""
            let name = app.localizedName ?? ""
            return cursorBundleHints.contains(where: { bundle.contains($0) || name.contains($0) })
                || name == "Cursor"
        }
    }

    func click(matching decision: ConfirmDecision) {
        guard AppSettings.shared.autoClickCursor else { return }
        guard trusted, let app = cursorApp else { return }
        let names = decision == .approve
            ? ["Allow", "Run", "Accept", "Continue", "确认", "运行", "允许", "继续"]
            : ["Cancel", "Reject", "Deny", "取消", "拒绝"]
        pressButton(in: app, names: names)
    }

    private func refresh() {
        trusted = AXIsProcessTrusted()
        isCursorRunning = cursorApp != nil
        guard AppSettings.shared.watchCursorDialogs, trusted, let app = cursorApp else { return }
        if let dialog = detectDialog(in: app) {
            if dialog != lastDialog {
                lastDialog = dialog
                Task {
                    let request = ConfirmRequest(
                        source: "cursor-ax",
                        kind: .agent,
                        title: "Cursor 需要确认",
                        message: dialog
                    )
                    _ = await ConfirmCenter.shared.submit(request)
                }
            }
        } else {
            lastDialog = ""
        }
    }

    private func detectDialog(in app: NSRunningApplication) -> String? {
        let appEl = AXUIElementCreateApplication(app.processIdentifier)
        var windows: AnyObject?
        guard AXUIElementCopyAttributeValue(appEl, kAXWindowsAttribute as CFString, &windows) == .success,
              let list = windows as? [AXUIElement] else { return nil }

        for window in list {
            var role: AnyObject?
            AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &role)
            let roleName = role as? String ?? ""
            var title: AnyObject?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title)
            let titleText = title as? String ?? ""
            let buttons = buttonTitles(in: window)
            let looksLikeConfirm = buttons.contains(where: {
                ["Allow", "Run", "Accept", "确认", "运行", "允许"].contains($0)
            })
            if looksLikeConfirm || roleName == "AXSheet" || titleText.localizedCaseInsensitiveContains("confirm") {
                let joined = ([titleText] + buttons).filter { !$0.isEmpty }.joined(separator: " · ")
                if !joined.isEmpty { return joined }
            }
        }
        return nil
    }

    private func buttonTitles(in element: AXUIElement) -> [String] {
        var titles: [String] = []
        var children: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children) == .success,
              let list = children as? [AXUIElement] else { return titles }
        for child in list {
            var role: AnyObject?
            AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &role)
            if (role as? String) == "AXButton" {
                var title: AnyObject?
                AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &title)
                if let text = title as? String, !text.isEmpty {
                    titles.append(text)
                }
            }
            titles.append(contentsOf: buttonTitles(in: child))
        }
        return titles
    }

    private func pressButton(in app: NSRunningApplication, names: [String]) {
        let appEl = AXUIElementCreateApplication(app.processIdentifier)
        var windows: AnyObject?
        guard AXUIElementCopyAttributeValue(appEl, kAXWindowsAttribute as CFString, &windows) == .success,
              let list = windows as? [AXUIElement] else { return }
        for window in list {
            if pressFirstMatch(in: window, names: names) { return }
        }
    }

    private func pressFirstMatch(in element: AXUIElement, names: [String]) -> Bool {
        var role: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        if (role as? String) == "AXButton" {
            var title: AnyObject?
            AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title)
            if let text = title as? String, names.contains(text) {
                AXUIElementPerformAction(element, kAXPressAction as CFString)
                return true
            }
        }
        var children: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children) == .success,
              let list = children as? [AXUIElement] else { return false }
        for child in list {
            if pressFirstMatch(in: child, names: names) { return true }
        }
        return false
    }
}
