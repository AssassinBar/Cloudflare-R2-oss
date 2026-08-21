import AppKit
import SwiftUI

@MainActor
final class ConfirmHUDController {
    nonisolated(unsafe) static let shared = ConfirmHUDController()

    private var panel: NSPanel?
    private var hosting: NSHostingView<ConfirmHUDView>?

    func show(center: ConfirmCenter) {
        if panel == nil {
            let view = ConfirmHUDView(center: center)
            let hostingView = NSHostingView(rootView: view)
            hostingView.frame = NSRect(x: 0, y: 0, width: 420, height: 520)
            let panel = NSPanel(
                contentRect: hostingView.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.isMovableByWindowBackground = true
            panel.hidesOnDeactivate = false
            panel.contentView = hostingView
            self.panel = panel
            self.hosting = hostingView
        }
        position()
        panel?.alphaValue = 1
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
        panel?.alphaValue = 0
    }

    private func position() {
        guard let panel, let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let origin = CGPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2 + 40
        )
        panel.setFrameOrigin(origin)
    }
}

struct ConfirmHUDView: View {
    @ObservedObject var center: ConfirmCenter
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 16) {
            Text(settings.catchphrase)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.top, 8)

            XiaoAiOrbView(
                phase: center.phase,
                audioLevel: center.audioLevel
            )
            .frame(width: 210 * settings.hudScale, height: 210 * settings.hudScale)

            if let current = center.current {
                VStack(spacing: 8) {
                    Text(current.kind.zhTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(XiaoAiTheme.glow)
                    Text(current.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(current.message)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .lineLimit(5)
                    if !center.transcript.isEmpty {
                        Text("听到：\(center.transcript)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .padding(.horizontal, 8)

                HStack(spacing: 12) {
                    Button("取消") { center.decide(.reject, via: .click, transcript: "") }
                        .buttonStyle(HUDButtonStyle(role: .reject))
                        .keyboardShortcut(.escape, modifiers: [])
                    Button("确认") { center.decide(.approve, via: .click, transcript: "") }
                        .buttonStyle(HUDButtonStyle(role: .approve))
                        .keyboardShortcut(.return, modifiers: [])
                }
                .padding(.bottom, 10)
            }
        }
        .padding(22)
        .frame(width: 380)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(XiaoAiTheme.night.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(XiaoAiTheme.orange.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: XiaoAiTheme.orange.opacity(0.25), radius: 28)
        )
    }
}

private struct HUDButtonStyle: ButtonStyle {
    enum Role { case approve, reject }
    var role: Role

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(role == .approve ? XiaoAiTheme.orange : Color.white.opacity(0.12))
                    .opacity(configuration.isPressed ? 0.75 : 1)
            )
    }
}
