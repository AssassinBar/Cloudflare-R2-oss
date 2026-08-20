import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var tradeStore: TradeStore
    @EnvironmentObject private var notificationManager: NotificationManager

    @State private var showLogoutConfirm = false
    @State private var avatarRotation: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                profileHeader
                    .staggeredAppear(index: 0)

                statsCard
                    .staggeredAppear(index: 1)

                settingsSection
                    .staggeredAppear(index: 2)

                logoutButton
                    .staggeredAppear(index: 3)

                Text("CryptoLedger v1.0")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.2))
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .alert("确认退出", isPresented: $showLogoutConfirm) {
            Button("取消", role: .cancel) {}
            Button("退出登录", role: .destructive) {
                authService.logout()
                tradeStore.clearUserData()
            }
        } message: {
            Text("退出后需要重新登录才能查看您的交易记录")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                LiquidGlassTheme.accentCyan.opacity(0.3),
                                LiquidGlassTheme.accentPurple.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .blur(radius: 20)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [LiquidGlassTheme.accentCyan, LiquidGlassTheme.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay {
                        Text(String(authService.displayName.prefix(1)).uppercased())
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .liquidGlass(cornerRadius: 36)
                    .rotation3DEffect(.degrees(avatarRotation), axis: (x: 0, y: 1, z: 0))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                    avatarRotation = 15
                }
            }

            VStack(spacing: 4) {
                Text(authService.displayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text(authService.currentUser?.email ?? "")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
    }

    private var statsCard: some View {
        GlassCard {
            HStack(spacing: 0) {
                profileStat(value: "\(tradeStore.trades.count)", label: "总记录")
                Divider().frame(height: 40).opacity(0.15)
                profileStat(value: "\(tradeStore.openTrades.count)", label: "持仓中")
                Divider().frame(height: 40).opacity(0.15)
                profileStat(
                    value: String(format: "%.1f%%", tradeStore.summary.winRate),
                    label: "胜率"
                )
            }
        }
    }

    private func profileStat(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var settingsSection: some View {
        VStack(spacing: 10) {
            settingsRow(
                icon: "bell.badge",
                title: "推送通知",
                subtitle: notificationManager.isAuthorized ? "已开启" : "未授权",
                color: LiquidGlassTheme.accentCyan
            ) {
                notificationManager.requestAuthorization()
            }

            settingsRow(
                icon: "lock.shield",
                title: "数据安全",
                subtitle: "本地加密存储",
                color: LiquidGlassTheme.accentPurple
            )

            settingsRow(
                icon: "arrow.triangle.2.circlepath",
                title: "同步状态",
                subtitle: "本地存储",
                color: LiquidGlassTheme.accentGold
            )
        }
    }

    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: (() -> Void)? = nil
    ) -> some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.2))
            }
            .padding(14)
            .liquidGlass(cornerRadius: 16, opacity: 0.08)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var logoutButton: some View {
        Button {
            showLogoutConfirm = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("退出登录")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(LiquidGlassTheme.lossRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .liquidGlass(cornerRadius: 16, opacity: 0.08)
        }
        .buttonStyle(PressableButtonStyle())
    }
}
