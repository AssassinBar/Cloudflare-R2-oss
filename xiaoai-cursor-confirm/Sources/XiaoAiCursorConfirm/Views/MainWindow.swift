import SwiftUI

struct MainWindow: View {
    @EnvironmentObject private var center: ConfirmCenter
    @EnvironmentObject private var settings: AppSettings
    @State private var tab = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.10),
                    Color(red: 0.10, green: 0.08, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HStack(spacing: 0) {
                orbPane
                    .frame(width: 360)
                Divider().overlay(XiaoAiTheme.orange.opacity(0.15))
                VStack(spacing: 0) {
                    Picker("", selection: $tab) {
                        Text("测试对接").tag(0)
                        Text("设置").tag(1)
                        Text("日志").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(16)

                    switch tab {
                    case 1: SettingsView()
                    case 2: LogView()
                    default: TestDockView()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var orbPane: some View {
        VStack(spacing: 18) {
            Text(settings.catchphrase)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(XiaoAiTheme.glow.opacity(0.9))
                .padding(.top, 28)

            XiaoAiOrbView(phase: center.phase, audioLevel: center.audioLevel)
                .frame(width: 260, height: 260)

            statusChip

            if let current = center.current {
                VStack(spacing: 6) {
                    Text(current.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(current.message)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                Text("等待 Cursor 调用确认")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()
            Text(center.healthSummary())
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RadialGradient(
                colors: [XiaoAiTheme.orange.opacity(0.16), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 240
            )
        )
    }

    private var statusChip: some View {
        let live = center.serverRunning
        return HStack(spacing: 8) {
            Circle()
                .fill(live ? XiaoAiTheme.success : XiaoAiTheme.reject)
                .frame(width: 8, height: 8)
            Text(live ? "Cursor 对接已就绪" : "对接未启动")
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(.white.opacity(0.08)))
        .foregroundStyle(.white.opacity(0.85))
    }
}
