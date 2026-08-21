import SwiftUI

struct TestDockView: View {
    @EnvironmentObject private var center: ConfirmCenter
    @EnvironmentObject private var settings: AppSettings
    @State private var customTitle = "允许运行终端命令"
    @State private var customMessage = "python3 scripts/deploy.py --dry-run"
    @State private var customKind: ConfirmKind = .command
    @State private var lastJSON = ""
    @State private var busy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                XiaomiAuthView()
                scenarioGrid
                customCard
                curlCard
                if !lastJSON.isEmpty {
                    jsonCard
                }
            }
            .padding(20)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("测试对接")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text("先扫码或登录小米账号授权音箱。测试场景会弹出光球，并把确认词用小爱同学播报出来。")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private var scenarioGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(TestScenario.allCases) { scenario in
                Button {
                    Task {
                        busy = true
                        await center.runScenario(scenario)
                        lastJSON = pretty(center.lastResponse)
                        busy = false
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(scenario.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(scenario.subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(XiaoAiTheme.orange.opacity(0.18), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(busy)
            }
        }
    }

    private var customCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("自定义确认")
                .font(.headline)
                .foregroundStyle(.white)
            Picker("类型", selection: $customKind) {
                ForEach(ConfirmKind.allCases) { kind in
                    Text(kind.zhTitle).tag(kind)
                }
            }
            TextField("标题", text: $customTitle)
                .textFieldStyle(.roundedBorder)
            TextField("内容", text: $customMessage)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("弹出确认并播报") {
                    Task {
                        busy = true
                        let request = ConfirmRequest(
                            source: "test",
                            kind: customKind,
                            title: customTitle,
                            message: customMessage
                        )
                        _ = await center.submit(request)
                        lastJSON = pretty(center.lastResponse)
                        busy = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(XiaoAiTheme.orange)

                Button("只播报") {
                    Task {
                        center.phase = .speaking
                        await XiaoAiSpeaker.shared.speak("主人，\(customTitle)。\(customMessage)")
                        center.phase = .idle
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var curlCard: some View {
        let sample = """
        curl -sS http://127.0.0.1:\(settings.port)/v1/health

        curl -sS -X POST http://127.0.0.1:\(settings.port)/v1/confirm \\
          -H 'Content-Type: application/json' \\
          -d '{"source":"cursor","kind":"command","title":"允许运行终端命令","message":"npm test","timeoutMs":20000}'
        """
        return VStack(alignment: .leading, spacing: 8) {
            Text("CLI / Cursor 对接样例")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Cursor 规则、MCP 或脚本都可以 POST 到本机端口。下面可直接复制。")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Text(sample)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(XiaoAiTheme.glow)
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(.black.opacity(0.35)))
        }
        .padding(14)
        .background(cardBackground)
    }

    private var jsonCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近一次响应")
                .font(.headline)
                .foregroundStyle(.white)
            Text(lastJSON)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
                .textSelection(.enabled)
        }
        .padding(14)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.white.opacity(0.05))
    }

    private func pretty<T: Encodable>(_ value: T?) -> String {
        guard let value else { return "" }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value), let text = String(data: data, encoding: .utf8) else {
            return ""
        }
        return text
    }
}
