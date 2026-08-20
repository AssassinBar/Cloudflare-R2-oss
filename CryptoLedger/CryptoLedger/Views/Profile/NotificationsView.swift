import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var notificationManager: NotificationManager

    var body: some View {
        VStack(spacing: 0) {
            header

            if notificationManager.notifications.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "bell.slash",
                    title: "暂无通知",
                    subtitle: "交易平仓或持仓提醒会显示在这里"
                )
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(notificationManager.notifications.enumerated()), id: \.element.id) { index, notification in
                            NotificationCard(notification: notification)
                                .staggeredAppear(index: index)
                                .onTapGesture {
                                    withAnimation {
                                        notificationManager.markAsRead(notification)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("通知中心")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                if notificationManager.unreadCount > 0 {
                    Text("\(notificationManager.unreadCount) 条未读")
                        .font(.caption)
                        .foregroundStyle(LiquidGlassTheme.accentCyan)
                }
            }

            Spacer()

            if notificationManager.unreadCount > 0 {
                Button {
                    withAnimation {
                        notificationManager.markAllAsRead()
                    }
                } label: {
                    Text("全部已读")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(LiquidGlassTheme.accentCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .liquidGlass(cornerRadius: 10, opacity: 0.1)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

struct NotificationCard: View {
    let notification: AppNotification

    private var icon: String {
        switch notification.type {
        case .pnlAlert: return "chart.line.uptrend.xyaxis"
        case .tradeReminder: return "clock.badge.exclamationmark"
        case .system: return "info.circle"
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case .pnlAlert: return LiquidGlassTheme.accentGold
        case .tradeReminder: return LiquidGlassTheme.accentCyan
        case .system: return LiquidGlassTheme.accentPurple
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    if !notification.isRead {
                        Circle()
                            .fill(LiquidGlassTheme.accentCyan)
                            .frame(width: 7, height: 7)
                    }
                }

                Text(notification.body)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)

                Text(formatTime(notification.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
            }

            Spacer()
        }
        .padding(14)
        .liquidGlass(
            cornerRadius: 16,
            opacity: notification.isRead ? 0.06 : 0.12
        )
    }

    private func formatTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}
