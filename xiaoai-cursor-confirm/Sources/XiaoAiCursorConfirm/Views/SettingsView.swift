import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var center: ConfirmCenter
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var watcher = CursorAXWatcher.shared

    var body: some View {
        Form {
            Section("对接") {
                HStack {
                    Text("本地端口")
                    Spacer()
                    TextField("17880", value: $settings.port, format: .number)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Button(center.serverRunning ? "重启对接" : "启动对接") {
                        center.stopServer()
                        center.startServer()
                    }
                    if center.serverRunning {
                        Button("停止") { center.stopServer() }
                    }
                }
            }

            Section {
                XiaomiAuthView()
            }

            Section("本机语音（回退）") {
                TextField("唤醒口吻", text: $settings.catchphrase)
                Picker("中文语音", selection: $settings.voiceIdentifier) {
                    Text("自动（婷婷优先）").tag("")
                    ForEach(XiaoAiSpeaker.shared.availableVoices(), id: \.identifier) { voice in
                        Text("\(voice.name) · \(voice.language)").tag(voice.identifier)
                    }
                }
                HStack {
                    Text("语速")
                    Slider(value: $settings.speechRate, in: 0.35...0.58)
                }
                HStack {
                    Text("音调")
                    Slider(value: $settings.speechPitch, in: 0.9...1.25)
                }
                Toggle("播报后自动听取 确认 / 取消", isOn: $settings.autoListen)
            Button("试听一句（本机）") {
                    Task {
                        center.phase = .speaking
                        await XiaoAiSpeaker.shared.speak("主人，我在。Cursor 有一条确认请求。")
                        center.phase = .idle
                    }
                }
            }

            Section("Cursor") {
                LabeledContent("Cursor 进程") {
                    Text(watcher.isCursorRunning ? "已发现" : "未运行")
                        .foregroundStyle(watcher.isCursorRunning ? XiaoAiTheme.success : .secondary)
                }
                Toggle("监听 Cursor 确认对话框（辅助功能）", isOn: $settings.watchCursorDialogs)
                Toggle("语音确认后自动点击 Cursor 按钮", isOn: $settings.autoClickCursor)
                HStack {
                    Text(watcher.trusted ? "辅助功能已授权" : "需要辅助功能权限")
                    Spacer()
                    Button("授权") { watcher.requestTrust() }
                }
            }

            Section("界面") {
                HStack {
                    Text("光球大小")
                    Slider(value: $settings.hudScale, in: 0.8...1.4)
                }
                Toggle("登录时启动", isOn: $settings.launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 8)
    }
}

struct LogView: View {
    @EnvironmentObject private var center: ConfirmCenter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("事件日志")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button("清空") { center.logs.removeAll() }
            }
            .padding(.horizontal, 20)

            List(center.logs) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.at.formatted(date: .omitted, time: .standard))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.text)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(entry.level == "error" ? XiaoAiTheme.reject : .white)
                }
                .listRowBackground(Color.white.opacity(0.03))
            }
            .scrollContentBackground(.hidden)
        }
    }
}
