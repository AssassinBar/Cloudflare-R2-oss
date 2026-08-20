import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var notificationManager: NotificationManager

    var body: some View {
        VStack(spacing: 0) {
            header

            if notificationManager.notifications.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "bell",
                    title: "暂无通知",
                    subtitle: "平仓与持仓提醒会显示在这里"
                )
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(notificationManager.notifications.enumerated()), id: \.element.id) { index, notification in
                            NotificationCard(notification: notification)
                                .staggeredAppear(index: index)
                                .onTapGesture {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        notificationManager.markAsRead(notification)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 110)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("通知")
                    .font(.system(size: 26, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(LiquidGlassTheme.textPrimary)

                if notificationManager.unreadCount > 0 {
                    Text("\(notificationManager.unreadCount) 条未读")
                        .font(.system(size: 12))
                        .foregroundStyle(LiquidGlassTheme.textTertiary)
                }
            }

            Spacer()

            if notificationManager.unreadCount > 0 {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        notificationManager.markAllAsRead()
                    }
                } label: {
                    Text("全部已读")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(LiquidGlassTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}

struct NotificationCard: View {
    let notification: AppNotification

    private var icon: String {
        switch notification.type {
        case .pnlAlert: return "chart.line.uptrend.xyaxis"
        case .tradeReminder: return "clock"
        case .system: return "info.circle"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(LiquidGlassTheme.textTertiary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(notification.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(LiquidGlassTheme.textPrimary)

                    if !notification.isRead {
                        Circle()
                            .fill(LiquidGlassTheme.textPrimary.opacity(0.7))
                            .frame(width: 5, height: 5)
                    }
                }

                Text(notification.body)
                    .font(.system(size: 12))
                    .foregroundStyle(LiquidGlassTheme.textSecondary)
                    .lineLimit(2)
                    .lineSpacing(2)

                Text(formatTime(notification.createdAt))
                    .font(.system(size: 11))
                    .foregroundStyle(LiquidGlassTheme.textTertiary)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .liquidGlass(
            cornerRadius: 14,
            opacity: notification.isRead ? 0.03 : 0.07,
            borderOpacity: 0.1
        )
    }

    private func formatTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}
