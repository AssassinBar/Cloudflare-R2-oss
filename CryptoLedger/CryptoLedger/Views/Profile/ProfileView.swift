import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var tradeStore: TradeStore
    @EnvironmentObject private var notificationManager: NotificationManager

    @State private var showLogoutConfirm = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                profileHeader
                    .staggeredAppear(index: 0)

                statsCard
                    .staggeredAppear(index: 1)

                settingsSection
                    .staggeredAppear(index: 2)

                logoutButton
                    .staggeredAppear(index: 3)

                Text("CryptoLedger  1.0")
                    .font(.system(size: 11))
                    .tracking(0.5)
                    .foregroundStyle(LiquidGlassTheme.textTertiary.opacity(0.6))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .alert("确认退出", isPresented: $showLogoutConfirm) {
            Button("取消", role: .cancel) {}
            Button("退出登录", role: .destructive) {
                authService.logout()
                tradeStore.clearUserData()
            }
        } message: {
            Text("退出后需要重新登录才能查看交易记录")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 72, height: 72)

                Text(String(authService.displayName.prefix(1)).uppercased())
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(LiquidGlassTheme.textPrimary)
            }
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            }

            VStack(spacing: 4) {
                Text(authService.displayName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(LiquidGlassTheme.textPrimary)

                Text(authService.currentUser?.email ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(LiquidGlassTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            profileStat(value: "\(tradeStore.trades.count)", label: "总记录")
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 0.5, height: 36)
            profileStat(value: "\(tradeStore.openTrades.count)", label: "持仓")
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 0.5, height: 36)
            profileStat(
                value: String(format: "%.0f%%", tradeStore.summary.winRate),
                label: "胜率"
            )
        }
        .padding(.vertical, 18)
        .liquidGlass(cornerRadius: LiquidGlassTheme.cardCornerRadius)
    }

    private func profileStat(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(LiquidGlassTheme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(LiquidGlassTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var settingsSection: some View {
        VStack(spacing: 1) {
            settingsRow(
                icon: "bell",
                title: "推送通知",
                subtitle: notificationManager.isAuthorized ? "已开启" : "未授权"
            ) {
                notificationManager.requestAuthorization()
            }

            settingsRow(
                icon: "lock.shield",
                title: "数据安全",
                subtitle: "本地加密存储"
            )

            settingsRow(
                icon: "internaldrive",
                title: "存储",
                subtitle: "仅本机"
            )
        }
        .liquidGlass(cornerRadius: LiquidGlassTheme.cardCornerRadius, opacity: 0.05, borderOpacity: 0.1)
    }

    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        action: (() -> Void)? = nil
    ) -> some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(LiquidGlassTheme.textSecondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(LiquidGlassTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(LiquidGlassTheme.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LiquidGlassTheme.textTertiary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var logoutButton: some View {
        Button {
            showLogoutConfirm = true
        } label: {
            Text("退出登录")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LiquidGlassTheme.lossRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .liquidGlass(cornerRadius: 14, opacity: 0.04, borderOpacity: 0.1)
        }
        .buttonStyle(PressableButtonStyle())
    }
}
