import SwiftUI

struct SettingsView: View {
    @State private var useRemoteAPI = false
    @State private var baseURLString = "https://api.example.com"
    @State private var showSavedToast = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("接口配置")
                                .font(AppTheme.display(28))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("先跑通 UI 框架，再切换到真实后端。")
                                .font(AppTheme.body(15))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .appearAnimation(index: 0)

                        VStack(alignment: .leading, spacing: 16) {
                            Toggle(isOn: $useRemoteAPI.animation(AppAnimation.softSpring)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("使用远程 API")
                                        .font(AppTheme.body(15).weight(.medium))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(useRemoteAPI ? "RemoteInventoryService" : "MockInventoryService")
                                        .font(AppTheme.caption())
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                            .tint(AppTheme.accent)

                            if useRemoteAPI {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Base URL")
                                        .font(AppTheme.caption())
                                        .foregroundStyle(AppTheme.textSecondary)
                                    TextField("https://api.example.com", text: $baseURLString)
                                        .font(AppTheme.mono(13))
                                        .padding(12)
                                        .background(AppTheme.surfaceSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .keyboardType(.URL)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            PrimaryButton(title: "保存环境配置", icon: "checkmark") {
                                applyEnvironment()
                            }
                        }
                        .surfaceCard()
                        .appearAnimation(index: 1)

                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "对接说明")
                            bullet("在 `ServiceFactory` 中切换 Mock / Remote")
                            bullet("请求定义位于 `RemoteInventoryService.swift`")
                            bullet("按后端路径修改 `path` / `queryItems`")
                            bullet("登录后调用 `APIClient.setAuthToken`")
                        }
                        .surfaceCard()
                        .appearAnimation(index: 2)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("关于")
                                .font(AppTheme.title(18))
                            Text("库存通 · InventoryApp")
                                .font(AppTheme.body(14))
                                .foregroundStyle(AppTheme.textSecondary)
                            Text("原生 SwiftUI 进销存框架")
                                .font(AppTheme.caption())
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .surfaceCard()
                        .appearAnimation(index: 3)
                    }
                    .padding(AppTheme.pagePadding)
                }

                if showSavedToast {
                    VStack {
                        Spacer()
                        Text("已保存，重启后模块将使用新数据源")
                            .font(AppTheme.caption())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppTheme.textPrimary.opacity(0.92))
                            .clipShape(Capsule())
                            .padding(.bottom, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(AppAnimation.spring, value: showSavedToast)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(AppTheme.accent)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private func applyEnvironment() {
        if useRemoteAPI, let url = URL(string: baseURLString), !baseURLString.isEmpty {
            AppEnvironment.current = .remote(baseURL: url)
        } else {
            AppEnvironment.current = .mock
            useRemoteAPI = false
        }

        withAnimation(AppAnimation.spring) { showSavedToast = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation(AppAnimation.fade) { showSavedToast = false }
        }
    }
}
